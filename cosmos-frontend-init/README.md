# Developing COSMOS Frontend Applications

NOTE: All commands are assumed to be executed from this (cosmos-frontend-init) directory

1.  Bootstrap the frontend with yarn

        cosmos-frontend-init> yarn

1.  Start cosmos

        cosmos-frontend-init> cd ..
        COSMOS> cosmos_control.bat start

1.  Serve a local COSMOS application (CmdTlmServer, ScriptRunner, etc)

        cosmos-frontend-init> cd packages/cosmosc2-tool-scriptrunner
        cosmosc2-tool-scriptrunner> yarn serve

1.  Set the single SPA override for the application

    Visit localhost:2900 and Right-click 'Inspect'<br>
    In the console paste:

        localStorage.setItem('devtools', true)

    Refresh and you should see {...} in the bottom right<br>
    Click the Default button next to the application (@cosmosc2/tool-scriptrunner)<br>
    Paste in the development path which is dependent on the port returned by the local yarn serve and the tool name (scriptrunner)

        http://localhost:2914/tools/scriptrunner/js/app.js

# Developing COSMOS Base Application

1.  Run a development version of traefik

        cosmos-frontend-init> cd ../traefik
        traefik> docker stop cosmos-traefik
        traefik> docker build -f Dockerfile-dev-base -t cosmos-traefik-dev-base .
        traefik> docker run --network=cosmos -p 2900:80 -it --rm cosmos-traefik-dev-base

1.  Serve a local base application (App, Auth, AppBar, AppFooter, etc)

        cosmos-frontend-init> cd cosmosc2-tool-base
        cosmosc2-tool-base> yarn serve

# API development

1.  Run a development version of traefik

        cosmos-frontend-init> cd ../traefik
        traefik> docker stop cosmos-traefik
        traefik> docker build -f Dockerfile-dev -t cosmos-traefik-dev .
        traefik> docker run --network=cosmos -p 2900:80 -it --rm cosmos-traefik-dev

1.  Run a local copy of the API server

        cosmos-frontend-init> cd ../cosmos-cmd-tlm-api
        cosmos-cmd-tlm-api> docker stop cosmos-cmd-tlm-api
        cosmos-cmd-tlm-api> rails s
