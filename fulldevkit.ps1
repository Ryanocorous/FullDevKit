# fulldevkit.ps1 — my "is this machine actually ready to work" checker
# -------------------------------------------------------------------
#  Read the README.MD first.
#
# Run it with RUN_ME.bat (handles the admin prompt for me) or open in
# ISE and hit F5 if I'm already elevated.
#
# Installs: system stuff via winget, the JS bits via npm, py packages via pip.

# OneDrive keeps stamping this with the "downloaded from internet" flag and
# then PowerShell refuses to run it. Strip that off ourselves so I stop
# fighting the execution policy every single time. (lost an evening to this)
try { Unblock-File -Path $MyInvocation.MyCommand.Path -ErrorAction SilentlyContinue } catch {}

Write-Host "`n[*] Right, let's see what this machine is missing...`n"
$failed = $false
$hasPip = $false

# winget won't install system-wide unless we're admin. RUN_ME.bat elevates,
# but if someone runs the ps1 directly, warn them before everything fails.
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[WARN] Not admin - installs will probably faceplant."
    Write-Host "       Just use RUN_ME.bat, it sorts the elevation out.`n"
}

# After winget drops a new tool, PATH in THIS session is still stale, so the
# re-check can't see it. Re-read PATH straight from the registry to fix that.
function Refresh-Path {
    $m = [Environment]::GetEnvironmentVariable("Path","Machine")
    $u = [Environment]::GetEnvironmentVariable("Path","User")
    $env:Path = (@($m, $u) | Where-Object { $_ }) -join ";"
}

function Have-Winget {
    return ($null -ne (Get-Command winget -ErrorAction SilentlyContinue))
}

# The workhorse: is $cmd on the machine? If yes, great. If not, install it
# the right way for its ecosystem, refresh PATH, then check again so we can
# honestly say whether it worked.
function Ensure-Tool {
    param(
        [string]$name,
        [string]$cmd,
        [string]$method,    # winget for system tools, npm for the JS ones
        [string]$package,   # winget id, or npm name(s) - space separated is fine
        [string]$manualFix  # what to tell me if the auto-install gives up
    )

    $c = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($c) {
        Write-Host "[OK]    $name --> $($c.Source)"
        return
    }

    Write-Host "[MISS]  $name not here - grabbing it via $method ($package)..."
    try {
        switch ($method) {
            "winget" {
                if (Have-Winget) {
                    # --disable-interactivity is load-bearing: without it winget
                    # likes to sit there waiting on a keypress and LOOK frozen.
                    winget install --id $package -e --silent --disable-interactivity --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
                } else {
                    Write-Host "        no winget on this box, can't auto-install."
                }
            }
            "npm" {
                if (Get-Command npm -ErrorAction SilentlyContinue) {
                    # NOTE TO SELF: do NOT name this $args. that's a reserved
                    # automatic var and it silently nukes the splat, npm then
                    # tries a local install in System32 and barfs ENOENT. burned.
                    $pkgArr = $package -split '\s+'
                    & npm install -g @pkgArr --no-fund --no-audit --no-progress 2>&1 | Out-Null
                } else {
                    Write-Host "        npm's not ready yet (need Node first)."
                }
            }
        }
    } catch {
        Write-Host "        install blew up: $($_.Exception.Message)"
    }

    Refresh-Path
    $c = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($c) {
        Write-Host "[FIXED] $name sorted --> $($c.Source)"
    } else {
        Write-Host "[FAIL]  couldn't get $name in on its own"
        if ($manualFix) { Write-Host "        do it by hand: $manualFix" }
        $script:failed = $true
    }
}

# Lighter touch for things that come bundled with something else (npm/npx
# ride along with Node) - no point trying to install these separately.
function Check-Cmd($name, $cmd, $fix) {
    $c = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($null -eq $c) {
        Write-Host "[MISS]  $name missing"
        if ($fix) { Write-Host "        Fix: $fix" }
        $script:failed = $true
    } else {
        Write-Host "[OK]    $name --> $($c.Source)"
    }
}

# pip packages, feel free to add more or rq more
$pipPackageMap = @{
    "numpy"         = "numpy"
    "pandas"        = "pandas"
    "requests"      = "requests"
    "flask"         = "flask"
    "fastapi"       = "fastapi"
    "uvicorn"       = "uvicorn"
    "sqlalchemy"    = "sqlalchemy"
    "pytest"        = "pytest"
    "black"         = "black"
    "mypy"          = "mypy"
    "httpx"         = "httpx"
    "pydantic"      = "pydantic"
    "python-dotenv" = "python-dotenv"
    "rich"          = "rich"
    "typer"         = "typer"
    "celery"        = "celery"
    "redis"         = "redis"
    "pillow"        = "pillow"
    "matplotlib"    = "matplotlib"
    "scikit-learn"  = "scikit-learn"
    "dash"          = "dash"
    "pygame"        = "pygame"
}

# ---- the stuff nothing works without ----
Write-Host "`n--- Core Runtime ---`n"
Ensure-Tool "Node.js" node   "winget" "OpenJS.NodeJS.LTS" "Install https://nodejs.org"
# npm + npx hitch a ride with Node, so don't reinstall - just confirm they came along
Check-Cmd   "npm" npm "Reinstall Node.js"
Check-Cmd   "npx" npx "Reinstall Node.js"
Ensure-Tool "Git"     git    "winget" "Git.Git"          "Install https://git-scm.com"

# ---- package managers ----
Write-Host "`n--- Package Managers ---`n"
Ensure-Tool "pnpm" pnpm "npm" "pnpm" "npm i -g pnpm"
Ensure-Tool "yarn" yarn "npm" "yarn" "npm i -g yarn"

# ---- the front-end toolbelt ----
Write-Host "`n--- Frontend Tooling ---`n"
Ensure-Tool "TypeScript" tsc      "npm" "typescript"          "npm i -g typescript"
Ensure-Tool "ESLint"     eslint   "npm" "eslint"              "npm i -g eslint"
Ensure-Tool "Prettier"   prettier "npm" "prettier"            "npm i -g prettier"
Ensure-Tool "Vite"       vite     "npm" "vite"                "npm i -g vite"
Ensure-Tool "Webpack"    webpack  "npm" "webpack webpack-cli" "npm i -g webpack webpack-cli"

# ---- python side ----
Write-Host "`n--- Python Environment ---`n"
Ensure-Tool "Python" python "winget" "Python.Python.3.12" "Install from https://python.org"

# pip normally rides in with Python. If it somehow didn't, ensurepip can
# usually conjure it back without a full reinstall.
try {
    $pipVersion = pip --version 2>$null
    if ($LASTEXITCODE -eq 0 -and $pipVersion) {
        Write-Host "[OK]    pip version: $pipVersion"
        $hasPip = $true
    } else {
        throw
    }
} catch {
    Write-Host "[MISS]  no pip - trying to bootstrap it with ensurepip..."
    try {
        python -m ensurepip --upgrade 2>$null | Out-Null
        Refresh-Path
        $pipVersion = pip --version 2>$null
        if ($LASTEXITCODE -eq 0 -and $pipVersion) {
            Write-Host "[FIXED] pip back in business: $pipVersion"
            $hasPip = $true
        } else {
            throw
        }
    } catch {
        Write-Host "[FAIL]  ensurepip didn't take."
        Write-Host "        manual: https://pip.pypa.io/en/stable/installation/"
        $failed = $true
    }
}

# ---- heavier build deps, larger files, slower download  ----
Write-Host "`n--- Build Dependencies ---`n"
Write-Host "This may take a while"
Ensure-Tool "Java"     java   "winget" "Microsoft.OpenJDK.17" "Install a JDK"
Ensure-Tool ".NET SDK" dotnet "winget" "Microsoft.DotNet.SDK.8" "Install from https://dotnet.microsoft.com"

# Build Tools is the big one - several GB. vswhere is the proper way MS wants
# you to detect it rather than poking around in the registry.
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) {
    Write-Host "[OK]    Visual Studio Build Tools detected"
} else {
    Write-Host "[MISS]  Build Tools missing - installing. go make a coffee, this one's huge."
    if (Have-Winget) {
        winget install --id Microsoft.VisualStudio.2022.BuildTools -e --silent --disable-interactivity --accept-source-agreements --accept-package-agreements 2>&1 | Out-Null
        if (Test-Path $vswhere) {
            Write-Host "[FIXED] Build Tools in"
        } else {
            Write-Host "[FAIL]  Build Tools wouldn't go in"
            Write-Host "        manual: grab 'Build Tools for Visual Studio'"
            $failed = $true
        }
    } else {
        Write-Host "[FAIL]  no winget - install Build Tools by hand."
        $failed = $true
    }
}

# ---- sanity check the PATH ----
# half the "it's installed but not found" headaches come down to PATH, so
# eyeball the important ones. fresh terminal usually fixes any stragglers.
Write-Host "`n--- PATH Health ---`n"
Refresh-Path
$paths = $env:Path -split ";"
$critical = @("node", "git", "npm")
foreach ($c in $critical) {
    $match = $paths | Where-Object { $_ -match $c }
    if ($match) {
        Write-Host "[OK]    $c is on PATH"
    } else {
        Write-Host "[WARN]  $c not on PATH this session"
        Write-Host "        (new terminal almost always picks it up - don't panic)"
    }
}

# ---- now make sure my python libs are all there ----
if ($hasPip) {
    Write-Host "`n--- Checking Python Packages ---`n"

    # freeze format is the easy one to parse - "name==version" per line, no
    # header junk to skip like the default pip list table gives you.
    $installedRaw   = pip list --format=freeze 2>$null
    $installedNames = $installedRaw | ForEach-Object { ($_ -split "==")[0].ToLower().Trim() }

    foreach ($pkg in $pipPackageMap.Keys) {
        # pip treats _ and - the same, normalise so I don't double-install
        $normalised = $pkg.ToLower().Replace("_", "-")
        if ($installedNames -contains $normalised) {
            Write-Host "[OK]    $pkg already here"
        } else {
            Write-Host "[WAIT]  $pkg missing - pulling it in..."
            try {
                pip install $pkg --quiet 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[FIXED] $pkg done"
                } else {
                    throw
                }
            } catch {
                Write-Host "[FAIL]  $pkg wouldn't install"
                $script:failed = $true
            }
        }
    }

    Write-Host "`n--- Installed Python Packages ---`n"
    try {
        pip list
    } catch {
        Write-Host "[WARN]  couldn't dump the pip list"
    }
}

# ---- verdict ----
Write-Host "`n========================"
if ($failed) {
    Write-Host "Not quite there - check the [FAIL] lines above."
    Write-Host "Usually just needs a fresh terminal + one more run to settle."
} else {
    Write-Host "All good. Machine's ready to actually work."
}
Write-Host "========================`n"
