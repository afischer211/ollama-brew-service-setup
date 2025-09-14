# Ollama Homebrew Service Setup

This repository provides a set of scripts to simplify the setup and management of
[Ollama](https://ollama.com/) as a background service on macOS using Homebrew.

It allows you to easily configure Ollama with environment variables
(e.g., `OLLAMA_HOST`, `OLLAMA_MODELS`) by using a `.env` file, which is not
natively supported by Homebrew services.

## Features

- **Automated Plist Configuration**: Automatically generates the required
  `homebrew.mxcl.ollama.plist` file in `~/Library/LaunchAgents`.
- **Easy Environment Variable Management**: Updates the Ollama service
  configuration from a standard `.env` file in your project root.
- **Simple Service Control**: Provides convenient scripts to start, stop, and
  view logs for the Ollama service.

## Installation

### Prerequisites

- **macOS**
- **Homebrew**: If not installed, see [brew.sh](https://brew.sh/).
- **Ollama**: You must have Ollama installed via Homebrew.

  ```bash
  brew install ollama
  ```

### Setup

1.  **Clone this repository**:

    ```bash
    git clone https://github.com/ntrlmt/ollama-brew-service-setup.git
    cd ollama-brew-service-setup
    ```

2.  **Run the setup script**:

    This script will create the service file and apply any environment
    variables.

    ```bash
    ./scripts/update-ollama-brew-plist-env-vars.sh
    ```

    This creates the initial
    `~/Library/LaunchAgents/homebrew.mxcl.ollama.plist` file based on the
    template in this repository.

## Usage

### 1. Configure Environment Variables (Optional)

To customize Ollama's settings, create a `.env` file by copying the example
file.

```bash
cp .env.example .env
```

Edit the `.env` file to set your desired variables. For example:

```dotenv
# Make Ollama accessible on your local network
OLLAMA_HOST=0.0.0.0

# Store models on an external drive
OLLAMA_MODELS=/Volumes/External/ollama_models
```

After editing `.env`, **you must run the update script again** to apply the
changes to the service:

```bash
./scripts/update-ollama-brew-plist-env-vars.sh
```

### 2. Service Management

-   **Start the service**:

    ```bash
    ./scripts/start-ollama-brew-service.sh
    ```

-   **Stop the service**:

    ```bash
    ./scripts/stop-ollama-brew-service.sh
    ```

-   **Check service status**:

    ```bash
    brew services list
    ```

    You should see `ollama` listed with a "started" status.

-   **View logs**:

    ```bash
    ./scripts/log-ollama-brew-service.sh
    ```

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
