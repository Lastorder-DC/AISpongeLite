"""Local text-to-speech module that selects models based on character.

This mirrors the interface of the original :mod:`tts` module while
using locally hosted models from the :mod:`TTS` library.  Each supported
character maps to a different model so that callers can request distinct
voices.
"""

from asyncio import get_running_loop, sleep, wait_for
from io import BytesIO
import logging
from pathlib import Path

import numpy as np
from pydub import AudioSegment
from TTS.api import TTS

_log = logging.getLogger(__name__)

# Timeout for generation before retrying
_tts_timeout = 120

_model_root = Path(__file__).with_name("tts_models")

# Cache instantiated TTS models so each model is loaded only once.
_tts_instances: dict[str, TTS] = {}


def _get_tts(character: str) -> TTS:
    """Return a TTS instance for *character* loading it if necessary."""

    char = character.lower()
    model_dir = _model_root / char
    model_path = model_dir / "model.pth"
    config_path = model_dir / "config.json"
    key = str(model_dir)
    if key not in _tts_instances:
        _tts_instances[key] = TTS(model_path=str(model_path), config_path=str(config_path))
    return _tts_instances[key]


async def speak(character: str, text: str) -> AudioSegment:
    """Generate speech for the provided text using a model per character.

    :param character: Character name used to select the voice model
    :param text: Text to synthesize
    :return: :class:`pydub.AudioSegment` containing the spoken audio
    """

    result = None
    err_count = 0

    while result is None:
        try:
            tts_model = _get_tts(character)
            _log.debug("Generating line with %s: (%s) %s", tts_model.model_name, character, text)

            def _generate():
                # Run the blocking synthesis call in a thread executor
                wav = tts_model.tts(text)
                audio = np.array(wav, dtype=np.float32)
                # Convert floating point audio to 16-bit PCM
                pcm = (audio * 32767).astype(np.int16)
                with BytesIO() as buf:
                    buf.write(pcm.tobytes())
                    buf.seek(0)
                    segment = AudioSegment(
                        buf.read(),
                        frame_rate=tts_model.synthesizer.output_sample_rate,
                        sample_width=2,
                        channels=1,
                    )
                return segment

            result = await wait_for(
                get_running_loop().run_in_executor(None, _generate),
                _tts_timeout,
            )
        except Exception as e:
            err_count += 1
            _log.exception("Local TTS generation failed %d times", err_count)
            await sleep(2 * err_count)
            if err_count > 10:
                _log.exception("Giving up local TTS generation")
                raise e

    return result
