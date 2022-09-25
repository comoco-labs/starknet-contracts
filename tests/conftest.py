import asyncio
import pytest


@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()
