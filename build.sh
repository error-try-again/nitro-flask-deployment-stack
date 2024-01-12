#!/bin/env bash

# Clone or update a git repository
clone_or_update_repo() {
    local repo_url=$1
    local repo_path=$2

    if [[ -d "${repo_path}/.git" ]]; then
        echo "Updating repository in ${repo_path}"
        git -C "${repo_path}" pull
  else
        echo "Cloning repository from ${repo_url} to ${repo_path}"
        git clone "${repo_url}" "${repo_path}"
  fi
}

# Create Flask App Dockerfile
create_flask_dockerfile() {
    cat > "${FLASK_APP_DOCKERFILE}" << EOF
# Official Python runtime as a parent image
FROM python:3.8
LABEL authors="void"

# Optionally install networking tools (for testing)
# RUN apt-get update && apt-get install -y curl iputils-ping

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy the current directory contents into the container at /usr/src/app
COPY . .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Make port ${FLASK_APP_PORT} available to the world outside this container
EXPOSE ${FLASK_APP_PORT}

# Define environment variable
ENV FLASK_ENV=production

# Run app.py when the container launches
CMD ["python", "./severity-matrix-api.py"]
EOF
}

# Create Nitro API Dockerfile
create_nitro_dockerfile() {
    cat > "${NITRO_API_DOCKERFILE}" << EOF
# Node.js latest for the base image
FROM node:latest
LABEL authors="void"

# Optionally install networking tools (for testing)
# RUN apt-get update && apt-get install -y curl iputils-ping

# Create app directory
WORKDIR /usr/src/app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install app dependencies
RUN npm install

# Copy the current directory contents into the container at /usr/src/app
COPY . .

# Build the app
RUN npm run build

# Expose port ${NITRO_API_PORT} to the outside world
EXPOSE ${NITRO_API_PORT}

# Run the application in preview mode
CMD ["npm", "run", "preview"]
EOF
}

# Modify the Frontend App Dockerfile
modify_nginx_dockerfile() {
    if [[ "${MOD_NGINX}" == true ]]; then
        echo "Modifying Frontend App Dockerfile: ${FRONTEND_APP_DOCKERFILE}"

        # Read the Dockerfile into a variable
        DOCKERFILE_CONTENTS=$(< "${FRONTEND_APP_DOCKERFILE}")

        # The command to be inserted
        COPY_CMD="COPY ../nitro-api/public/.well-known/ai-plugins.json /usr/share/nginx/html/.well-known/"

        # Insert the COPY command after the specified line
        MODIFIED_CONTENTS=$(echo "${DOCKERFILE_CONTENTS}" | sed "/RUN mkdir -p \/usr\/share\/nginx\/html\/\.well-known\/acme-challenge &&     chmod -R 777 \/usr\/share\/nginx\/html\/\.well-known/a ${COPY_CMD}")

        # Write the modified content back into the Dockerfile
        echo "${MODIFIED_CONTENTS}" > "${FRONTEND_APP_DOCKERFILE}"

  else
        echo "Frontend App Dockerfile not found at: ${FRONTEND_APP_DOCKERFILE}"
  fi
}

# Create docker-compose.yml
create_docker_compose() {
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  flask-app:
    build:
      context: ${FLASK_APP_CONTEXT}
    ports:
      - "${FLASK_APP_PORT}:${FLASK_APP_PORT}"
    environment:
      - FLASK_ENV=production
    restart: always

  nitro-api:
    build:
      context: ${NITRO_API_CONTEXT}
    ports:
      - "${NITRO_API_PORT}:${NITRO_API_PORT}"
    environment:
      - FLASK_API_URL=http://flask-app:${FLASK_APP_PORT}
    restart: always
    depends_on:
      - flask-app

EOF
}

# Append Flask and Nitro API services to existing docker-compose.yml
append_to_docker_compose() {
    # Backup original file
    cp docker-compose.yml docker-compose.yml.backup

    # Define new services configuration
    local new_services="
  flask-app:
    build:
      context: ${FLASK_APP_CONTEXT}
    ports:
      - \"${FLASK_APP_PORT}:${FLASK_APP_PORT}\"
    environment:
      - FLASK_ENV=production
    restart: always
    networks:
      - qrgen"

    local nitro_service="
  nitro-api:
    build:
      context: ${NITRO_API_CONTEXT}
    ports:
      - \"${NITRO_API_PORT}:${NITRO_API_PORT}\"
    environment:
      - FLASK_API_URL=http://flask-app:${FLASK_APP_PORT}
    restart: always
    depends_on:
      - flask-app
    networks:
      - qrgen"

  if [[ "${VOLUME}" == true ]]; then
        nitro_service+="
    volumes:
      - nginx-shared-volume:/usr/src/app/public/.well-known/"
  fi

    new_services+="${nitro_service}"

    # Use awk to insert new services immediately after 'services:' line
    awk -v new="${new_services}" '/^services:/{print;print new;next}1' docker-compose.yml.backup > docker-compose.yml
}

# Check the command line arguments for a specific flag and return true or false accordingly
check_flag() {
  for arg in "$@"; do
    if [[ "${arg}" == "${1}" ]]; then
      echo true
      return
    fi
  done
  echo false
}

# Read the values from config.txt into variables with the same name
read_configuration() {
  local key
  local value
  while IFS='=' read -r key value; do
    eval "${key}='${value}'"
  done < config.txt
}

# Clone or update the repositories
handle_repositories() {
  clone_or_update_repo "${FLASK_APP_REPO_URL}" "${FLASK_APP_CONTEXT}"
  clone_or_update_repo "${NITRO_API_REPO_URL}" "${NITRO_API_CONTEXT}"
}

# Create the relevant Dockerfiles
handle_dockerfiles() {
  create_flask_dockerfile
  create_nitro_dockerfile
}

# Create or append to docker-compose.yml depending on the --amend flag
handle_docker_compose() {
  if [[ "${AMEND}" == true ]]; then
    echo "Appending to existing docker-compose.yml"
    append_to_docker_compose
  else
    echo "Creating new docker-compose.yml"
    create_docker_compose
  fi
}

# Main function
main() {
  AMEND=$(check_flag --amend "$@")
  VOLUME=$(check_flag --volume "$@")
  MOD_NGINX=$(check_flag --mod-nginx "$@")

  read_configuration
  handle_repositories
  handle_dockerfiles
  handle_docker_compose

  if [[ "${MOD_NGINX}" == true ]]; then
    modify_nginx_dockerfile
  fi
}
main "$@"
