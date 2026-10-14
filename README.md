# deploy_agent_niyokwizerwa-aristide
#___________________________________
# Scripting Summative Lab: Automated Infrastructure Agent

#️ System Architecture Strategy
This solution utilizes an interactive shell interface built natively within `deploy_agent.sh` to wrap, deploy, and manage the lifecycle of the Student Attendance Tracker app. An interactive selection flow was prioritized over basic positional parameters to provide continuous data sanitization, custom roster injection patterns, and safer session environment branching.

# Operational Workflow Layout

*   **Feature 1 (Infrastructure Sandboxing):** Performs strict environmental check protocols (verifying tools and verifying runtime outputs using `python3 --version`), halts file creation if permission issues occur, configures isolated workspaces, and locks down sensitive configuration permissions to `600`.
*   **Feature 2 (Isolated Runtime Controller):** Manages path context routing dynamically, automatically shifting terminal controls into the target sandbox instance folder so relative file generation pathways resolve natively without altering core code frameworks.
*   **Feature 3 (Log Cleanup & Compression Engine):** Targets active logs inside `reports/`, bundles operational traces securely into unified timestamped archives, and purges open files to eliminate file pollution.

# Process Safeguards & System Interrupt Routines (The Trap Engine)
A permanent, low-level signal capture intercept layer (`trap handle_interrupt SIGINT SIGTSTP`) runs asynchronously. 

If a user kills a deployment build tracking cycle prematurely using `Ctrl+C` or `Ctrl+Z`, the automation engine intercepts the exit event instantly:
1. It automatically isolates and zips whatever partial directories exist into a recovery file (`*_archive.zip`).
2. It executes an immediate `rm -rf` cleanup sweep on the broken sandbox folder path to prevent structural repository clutter.

# Verifying and Testing the Signal Intercept Trap
To demonstrate compliance with the error recovery cleanup metrics:
1. Run `./deploy_agent.sh` and select option `1`.
2. Name your sandbox placeholder `trap_test`.
3. When prompted to select a roster construction build option, press `Ctrl + C`.
4. Run `ls` in your terminal: the `attendance_tracker_trap_test` folder will be completely wiped from the directory tree, and a clean `attendance_tracker_trap_test_archive.zip` recovery asset will be securely left in its place.
 

   
