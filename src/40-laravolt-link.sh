#!/bin/sh
script_name="laravolt-link"

# Global configurations
: "${DISABLE_DEFAULT_CONFIG:=false}"
: "${APP_BASE_DIR:=/var/www/html}"

# Set default values for Laravolt automations
: "${AUTORUN_ENABLED:=false}"
: "${AUTORUN_DEBUG:=false}"

# Set default values for Laravolt link
: "${AUTORUN_LARAVOLT_LINK:=true}"

############################################################################
# Sanity Checks
############################################################################

debug_log() {
    if [ "$LOG_OUTPUT_LEVEL" = "debug" ] || [ "$AUTORUN_DEBUG" = "true" ]; then
        echo "👉 DEBUG ($script_name): $1" >&2
    fi
}

if [ "$DISABLE_DEFAULT_CONFIG" = "true" ] || [ "$AUTORUN_ENABLED" = "false" ]; then
    debug_log "Skipping Laravolt automations because DISABLE_DEFAULT_CONFIG is true or AUTORUN_ENABLED is false."
    exit 0
fi

############################################################################
# Functions
############################################################################

artisan_laravolt_link() {
    debug_log "Running Laravolt link command"
    echo "🔗 Running Laravolt link: \"php artisan laravolt:link\"..."

    if ! php "$APP_BASE_DIR/artisan" laravolt:link; then
        echo "❌ $script_name: Laravolt link command failed"
        return 1
    fi

    echo "✅ Laravolt link completed successfully"
    return 0
}

laravel_is_installed() {
    if [ ! -f "$APP_BASE_DIR/artisan" ]; then
        return 1
    fi

    if [ ! -d "$APP_BASE_DIR/vendor" ]; then
        return 1
    fi

    return 0
}

laravolt_is_installed() {
    # Check if laravolt:link command exists
    if ! php "$APP_BASE_DIR/artisan" list | grep -q "laravolt:link"; then
        return 1
    fi

    return 0
}

############################################################################
# Main
############################################################################

if laravel_is_installed; then
    debug_log "Laravel detected"
    debug_log "Automation settings:"
    debug_log "- Laravolt Link: $AUTORUN_LARAVOLT_LINK"

    if laravolt_is_installed; then
        debug_log "Laravolt package detected"
        echo "🤔 Checking for Laravolt automations..."

        if [ "$AUTORUN_LARAVOLT_LINK" = "true" ]; then
            artisan_laravolt_link
        fi
    else
        echo "👉 $script_name: Skipping Laravolt automations because Laravolt package is not installed."
    fi
else
    echo "👉 $script_name: Skipping Laravolt automations because Laravel is not installed."
fi
