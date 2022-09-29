build :; nile compile
clean :; nile clean
test  :; pytest tests/
prep  :; curl -o accounts.json http://localhost:5050/predeployed_accounts
