# Build and test
build :; nile compile
clean :; nile clean
test  :; pytest tests/
