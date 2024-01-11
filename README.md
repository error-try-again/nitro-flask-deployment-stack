# GitSubCompose

GitSubCompose aims to solve some of the challenges of manually configuring & maintaining large full-stack projects by auto-configuring & generating the containers required to run them.
I found that I had too many repos & stacks in my workflow to quickly test uncoupled features at a high level. 
Tying them all together in one neat package for testing, deployment or production can be a pain in the ass.  

## Typical Case
To *quickly* pull in multiple submodule repos that depend on each other into one & spin them up quickly on a single local or remote machine to test critical functionality at a high level.

## Features
- Auto-Configuration: Automatically sets up and configures the required containers for your full-stack projects.
- Simplified Workflow: Integrates multiple repositories and stacks for efficient testing and deployment.

## Getting Started
### Prerequisites

- Docker installed on your system.
- Basic understanding of Docker and containerization.

### Configuration

- Clone the GitSubCompose repository to your local machine.
- Configure the project by modifying the provided environment variable names across the config & shell script to suit your needs. 
- Replace the Git URLs, names, and port values as needed for your project.

  *Example configuration*
  
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

### Setup & Run

Execute the following commands in your terminal to build and run the containers:

```bash
./build.sh && docker compose build --no-cache && docker compose up
```

### Support

For support, issues, or feature requests, please file an issue on the GitSubCompose GitHub repository.
