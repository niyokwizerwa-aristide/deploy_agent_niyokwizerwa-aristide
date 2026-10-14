#!/bin/bash
# deploy_agent.sh - Automated Project Bootstrapping & Process Management
#_______________________________________________________________________

TEMPLATE_DIR="templates"
PROJECT_DIR=""
DEPLOY_ACTIVE=0
handle_interrupt() {
    echo ""
    echo "!! Deployment interrupted by user (signal received)."
    if [[ $DEPLOY_ACTIVE -eq 1 && -d "$PROJECT_DIR" ]]; then
        local zipname="${PROJECT_DIR}_archive.zip"
        echo ">> Zipping incomplete project into: $zipname"
        zip -rq "$zipname" "$PROJECT_DIR"
        echo ">> Removing incomplete directory: $PROJECT_DIR"
        rm -rf "$PROJECT_DIR"
        echo ">> Cleanup complete. Archive saved as $zipname"
    else
        echo ">> Nothing had been created yet, so nothing to archive."
    fi
    exit 130
}

enable_traps()  { trap handle_interrupt SIGINT SIGTSTP; }
disable_traps() { trap - SIGINT SIGTSTP; }

is_number() { [[ "$1" =~ ^[0-9]+$ ]]; }

ask_project_name() {
    local input
    read -r -p "Enter project name suffix (e.g. math101): " input
    if [[ -z "$input" || ! "$input" =~ ^[A-Za-z0-9_-]+$ ]]; then
        echo "Error: name must be non-empty and use only letters, numbers, - or _."
        return 1
    fi
    PROJECT_DIR="attendance_tracker_${input}"
    return 0
}

deploy_inner() {
    echo "Deploy the Application"

    local missing=0
    for tool in python3 zip; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "Error: required tool '$tool' is not installed."
            missing=1
        fi
    done
    [[ $missing -eq 1 ]] && return 1

    for f in attendance_checker.py config.json assets.csv; do
        if [[ ! -f "$TEMPLATE_DIR/$f" ]]; then
            echo "Error: missing template file $TEMPLATE_DIR/$f"
            return 1
        fi
    done

    echo -n "Pre-flight checks passed. Environment check verified: "
    python3 --version

    ask_project_name || return 1

    if [[ -e "$PROJECT_DIR" ]]; then
        read -r -p "'$PROJECT_DIR' already exists. Overwrite? (y/n): " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            rm -rf "$PROJECT_DIR"
        else
            echo "Aborted: existing directory left untouched."
            return 1
        fi
    fi

    enable_traps

    mkdir -p "$PROJECT_DIR/Helpers" "$PROJECT_DIR/reports" || { disable_traps; return 1; }
    DEPLOY_ACTIVE=1
    echo "Created directory structure in $PROJECT_DIR/"

    cp "$TEMPLATE_DIR/attendance_checker.py" "$PROJECT_DIR/attendance_checker.py"
    cp "$TEMPLATE_DIR/config.json"           "$PROJECT_DIR/Helpers/config.json"

    echo "How should Helpers/assets.csv be built?"
    echo "  A) Copy from template (first N students)"
    echo "  B) Generate a fresh roster (counts start at 0)"
    local opt n
    read -r -p "Choose A or B: " opt

    case "${opt^^}" in
        A)
            read -r -p "How many students to copy? " n
            if ! is_number "$n" || [[ $n -lt 1 ]]; then
                echo "Error: please enter a positive whole number."
                cleanup_failed_deploy; return 1
            fi
            head -n $((n + 1)) "$TEMPLATE_DIR/assets.csv" > "$PROJECT_DIR/Helpers/assets.csv"
            echo "Copied header + $n students from template."
            ;;
        B)
            read -r -p "How many students to generate? " n
            if ! is_number "$n" || [[ $n -lt 1 ]]; then
                echo "Error: please enter a positive whole number."
                cleanup_failed_deploy; return 1
            fi
            local names=("Alice Johnson" "Bob Smith" "Carol White" "David Brown" "Eve Davis")
            local csv="$PROJECT_DIR/Helpers/assets.csv"
            echo "Email,Names,Attendance Count,Absence Count" > "$csv"
            local i name email
            for ((i = 0; i < n; i++)); do
                if [[ $i -lt ${#names[@]} ]]; then
                    name="${names[$i]}"
                else
                    name="Student $((i + 1))"
                fi
                email="$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '.')@example.com"
                echo "${email},${name},0,0" >> "$csv"
            done
            sed -i.bak -E 's/("total_sessions": *)[0-9]+/\11/' "$PROJECT_DIR/Helpers/config.json"
            rm -f "$PROJECT_DIR/Helpers/config.json.bak"
            echo "Generated $n students; total_sessions set to 1."
            ;;
        *)
            echo "Error: invalid choice '$opt'."
            cleanup_failed_deploy; return 1
            ;;
    esac

    chmod +x "$PROJECT_DIR/attendance_checker.py"
    chmod 600 "$PROJECT_DIR/Helpers/config.json"
    echo "Permissions set successfully."

    read -r -p "Update attendance alert thresholds? (y/n): " upd
    if [[ "$upd" =~ ^[Yy]$ ]]; then
        local warn fail
        read -r -p "Warning threshold: " warn
        read -r -p "Failure threshold: " fail
        warn=${warn:-75}
        fail=${fail:-50}
        if ! is_number "$warn" || ! is_number "$fail" || [[ $warn -gt 100 || $fail -gt 100 ]]; then
            echo "Invalid thresholds (must be whole numbers 0-100). Keeping defaults."
        else
            local cfg="$PROJECT_DIR/Helpers/config.json"
            sed -i.bak -E "s/(\"warning\": *)[0-9]+/\1${warn}/" "$cfg"
            sed -i.bak -E "s/(\"failure\": *)[0-9]+/\1${fail}/" "$cfg"
            rm -f "$cfg.bak"
            echo "Thresholds updated: warning=${warn}, failure=${fail}"
        fi
    fi

    DEPLOY_ACTIVE=0
    disable_traps

    echo "Verifying deployment by running the application..."
    ( cd "$PROJECT_DIR" && python3 attendance_checker.py )
    echo "Deployment of $PROJECT_DIR complete."
}

deploy() {
    enable_traps
    deploy_inner
    local rc=$?
    disable_traps
    return $rc
}

cleanup_failed_deploy() {
    DEPLOY_ACTIVE=0
    disable_traps
    rm -rf "$PROJECT_DIR"
    echo "Deployment aborted; partial directory removed."
}

run_app() {
    echo " Run the Application"
    if [[ -z "$PROJECT_DIR" ]]; then
        ask_project_name || return 1
    fi

    if [[ ! -d "$PROJECT_DIR" ]]; then
        echo "Error: directory '$PROJECT_DIR' does not exist. Please deploy first."
        return 1
    fi

    echo " Launching Python Applicatio"
    echo "_____________________________________________"
    local original_dir=$(pwd)
    cd "$PROJECT_DIR" || return 1
    python3 attendance_checker.py
    cd "$original_dir"
    echo "_________________________________________________________________"
    echo " Application execution loop closed."
}

archive_logs() {
    echo "Archive Environment Session Logs "
    if [[ -z "$PROJECT_DIR" ]]; then
        ask_project_name || return 1
    fi

    local log_dir="$PROJECT_DIR/reports"
    if [[ ! -f "$log_dir/attendance.log" && ! -f "$log_dir/absent.log" ]]; then
        echo "️ Notice: No generated operational logs found inside '$log_dir/' to archive."
        return 0
    fi

    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local archive_name="log_archive_${timestamp}.zip"

    local original_dir=$(pwd)
    cd "$PROJECT_DIR" || return 1

    zip -q -r "$archive_name" reports/*.log
    if [[ $? -eq 0 ]]; then
        echo " Logs successfully archived into: $archive_name"
        rm -f reports/*.log
        echo " Live reports/ directory reset to an empty state."
    else
        echo " Error: Failed to generate backup zip package archive." >&2
    fi
    cd "$original_dir"
}

interactive_menu() {
    while true; do
        echo ""
              echo "   EXEMPLARY DEPLOYMENT COMPLIANCE ENGINE MAIN   "
        echo " 1) Deploy the Application Infrastructure"
        echo " 2) Execute Application"
        echo " 3) Archive Environment Session Logs"
        echo " 4) Exit Process Framework"

        read -r -p "Select choice (1-4): " menu_choice

        case "$menu_choice" in
            1) deploy ;;
            2) run_app ;;
            3) archive_logs ;;
            4) echo "Exiting script workspace. Goodbye!"; exit 0 ;;
            *) echo " Selection matching error. Choose options 1 through 4." ;;
        esac
    done
}

if [[ $# -eq 0 ]]; then
    interactive_menu
else
    case "$1" in
        --deploy)  deploy ;;
        --run)     run_app ;;
        --archive) archive_logs ;;
        *)
            echo "Usage: $0 [--deploy | --run | --archive]"
            exit 1
            ;;
    esac
fi
