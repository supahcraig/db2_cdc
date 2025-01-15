echo 'preparing the environment...'


alias up='docker compose up --build'
alias down='docker compose down --volumes'
alias debup='docker compose up connect --build'
alias debdown='docker compose down connect'
alias oraup='docker compose up oracle-db-source'
alias oradown='docker compose down oracle-db-source'


echo 'done!'
