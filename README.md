# Nitro Flask Deployment Stack 

Automated stack for building distributed nitro API + flask API architectures within docker. Wanted to tie them together in a neat package for testing, deployment or production. 

## Features
- Automatically sets up and configures required containers for distributed full-stack applications.

### Configuration

- Git clone.
- Configure the project by modifying the provided environment variable names across the config & shell script. 
- Replace the Git URLs, names, and port values as needed for your project.

  *Example*
  
  ```
      FLASK_APP_CONTEXT=./flask-app
      FLASK_APP_DOCKERFILE=./flask-app/Dockerfile
      FLASK_APP_REPO_URL=https://github.com/yourusername/flask-app.git
      FLASK_APP_PORT=5000
      NITRO_API_CONTEXT=./nitro-api
      NITRO_API_DOCKERFILE=./nitro-api/Dockerfile
      NITRO_API_REPO_URL=https://github.com/yourusername/nitro-api.git
      NITRO_API_PORT=3000
  ```

### Usage

Execute the following commands in your terminal to build and run the containers:

```bash
./build.sh && docker compose build --no-cache && docker compose up
```

# PR/Issues 

PRs welcome
