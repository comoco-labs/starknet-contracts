# Build and test
build :; nile compile
clean :; nile clean
prep  :; curl -o accounts.json http://localhost:5050/predeployed_accounts
test  :; pytest tests/
