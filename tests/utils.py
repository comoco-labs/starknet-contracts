from starkware.starkware_utils.error_handling import StarkException


def str_to_felt(text):
    return int.from_bytes(text.encode(), 'big')


def felt_to_str(felt):
    return felt.to_bytes(31, 'big').decode()


def to_uint(num):
    return (num & ((1 << 128) - 1), num >> 128)


def from_uint(uint):
    return uint[0] + (uint[1] << 128)


async def assert_revert(fun, reverted_with=None):
    try:
        await fun
        assert False
    except StarkException as err:
        _, error = err.args
        if reverted_with is not None:
            assert reverted_with in error['message']
