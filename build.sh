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
    local new_services
    new_services=$(cat <<EOF

  flask-app:
    build:
      context: ${FLASK_APP_CONTEXT}
    ports:
      - "${FLASK_APP_PORT}:${FLASK_APP_PORT}"
    environment:
      - FLASK_ENV=production
    restart: always
    networks:
      - qrgen

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
    networks:
      - qrgen
EOF
)
    # Insert new services after the last service in the services section
    awk -v n="${new_services}" '/^[[:space:]]+[^ ]/ && p {print n; p=0} {print} /^[[:space:]]+[^ ]/ {p=1}' docker-compose.yml.backup > docker-compose.yml
}


#######################################
# Main function
#######################################
main() {
  # Check for --amend flag
  AMEND=false
  if [[ "$1" == "--amend" ]]; then
    AMEND=true
  fi

  # Read configuration
  local key
  local value
  while IFS='=' read -r key value; do
    eval "${key}='${value}'"
  done < config.txt

  # Clone or update repositories
  clone_or_update_repo "${FLASK_APP_REPO_URL}" "${FLASK_APP_CONTEXT}"
  clone_or_update_repo "${NITRO_API_REPO_URL}" "${NITRO_API_CONTEXT}"

  # Generate Dockerfiles and docker-compose.yml
  create_flask_dockerfile

  create_nitro_dockerfile

    # Amend or create new docker-compose.yml
  if [[ "${AMEND}" == true ]]; then
    echo "Appending to existing docker-compose.yml"
    append_to_docker_compose
  else
    echo "Creating new docker-compose.yml"
    create_docker_compose
  fi

  echo "Dockerfiles and docker-compose.yml have been generated."

}

main "$@"
