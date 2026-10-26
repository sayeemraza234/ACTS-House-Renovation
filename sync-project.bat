@echo off
setlocal EnableExtensions EnableDelayedExpansion

cd /d "%~dp0"
title ACTS - GitHub Sync

echo.
echo ========================================
echo        ACTS GitHub Project Sync
echo ========================================
echo.

where git >nul 2>&1
if errorlevel 1 (
    echo ERROR: Git is not installed or is not available in PATH.
    goto :failed
)

git rev-parse --show-toplevel >nul 2>&1
if errorlevel 1 (
    echo ERROR: This file must be inside the Git project folder.
    goto :failed
)

for /f "delims=" %%R in ('git remote get-url origin 2^>nul') do set "REMOTE=%%R"
if not defined REMOTE (
    echo ERROR: The origin GitHub remote is not configured.
    goto :failed
)

for /f "delims=" %%B in ('git branch --show-current 2^>nul') do set "BRANCH=%%B"
if not defined BRANCH set "BRANCH=main"

echo Checking GitHub for updates (%BRANCH%)...
git fetch origin %BRANCH%
if errorlevel 1 (
    echo ERROR: Could not contact GitHub. Check your internet connection and GitHub login.
    goto :failed
)

for /f "tokens=1,2" %%A in ('git rev-list --left-right --count %BRANCH%...origin/%BRANCH% 2^>nul') do (
    set "LOCAL_COMMITS=%%A"
    set "REMOTE_COMMITS=%%B"
)

if not defined LOCAL_COMMITS set "LOCAL_COMMITS=0"
if not defined REMOTE_COMMITS set "REMOTE_COMMITS=0"

set "LOCAL_FILES_CHANGED="
for /f "delims=" %%A in ('git status --porcelain 2^>nul') do set "LOCAL_FILES_CHANGED=yes"

if "%REMOTE_COMMITS%" GTR "0" (
    if "%LOCAL_COMMITS%" GTR "0" goto :conflict
    if defined LOCAL_FILES_CHANGED goto :conflict

    echo GitHub has newer changes. Updating local files...
    git merge --ff-only origin/%BRANCH%
    if errorlevel 1 goto :failed
    echo.
    echo Local files are now up to date with GitHub.
    goto :success
)

if defined LOCAL_FILES_CHANGED (
    echo Local changes found. Saving and pushing them to GitHub...
    git add -A
    if errorlevel 1 goto :failed

    git diff --cached --quiet
    if errorlevel 1 (
        git commit -m "Sync local changes"
        if errorlevel 1 goto :failed
    )

    git push origin %BRANCH%
    if errorlevel 1 goto :failed
    echo.
    echo Local changes were pushed to GitHub.
    goto :success
)

if "%LOCAL_COMMITS%" GTR "0" (
    echo Local commits found. Pushing them to GitHub...
    git push origin %BRANCH%
    if errorlevel 1 goto :failed
    echo.
    echo Local commits were pushed to GitHub.
    goto :success
)

echo Local files and GitHub are already synchronized.
goto :success

:conflict
echo.
echo WARNING: Both this computer and GitHub have changes.
echo No files were changed and nothing was pushed.
echo Resolve the differences manually, then run this file again.
goto :failed

:success
echo.
echo Sync completed.
pause
exit /b 0

:failed
echo.
echo Sync was not completed.
pause
exit /b 1
