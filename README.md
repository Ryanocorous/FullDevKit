
> Windows only. Leans on winget (built into Windows 10/11), so it won't do anything useful on macOS or Linux.

Check and install if dev software is installed for web dev.

Includes: 

Python 3.12
pip

Java (OpenJDK 17)
.NET SDK 8
Visual Studio Build Tools 2022

Node.js
npm
npx
Git

pnpm
yarn

TypeScript
ESLint
Prettier
Vite
Webpack

numpy
pandas
requests
flask
fastapi
uvicorn
sqlalchemy
pytest
black
mypy
httpx
pydantic
python-dotenv
rich
typer
celery
redis
pillow
matplotlib
scikit-learn

Can be used to quickly set up whatever you need. Please let me know if you want me to add anything more.

Any issues, message me. Just read all of this first. You need to run it with the bat, both in same folder.

<!-- !\[fulldevkit running](docs/screenshot.png) -->

## What it checks (and fixes)

|Category|Tools|How it installs|
|-|-|-|
|Core runtime|Node.js, npm, npx, Git|winget|
|Package managers|pnpm, yarn|npm|
|Frontend tooling|TypeScript, ESLint, Prettier, Vite, Webpack|npm|
|Python|Python, pip|winget / ensurepip|
|Build deps|Java (JDK 17), .NET SDK 8, VS Build Tools|winget|
|Python libs|numpy, pandas, requests, flask, fastapi, pytest, black, and many more. I started by listing all but just check the code. ctrl-f "python libraries".

Anything already present is left alone. Anything missing gets pulled in automatically.

## Running it

**Easiest thing ever to use, literally just download the folder, extract if zipped, and double-click `RUN\_ME.bat`.** It elevates to admin (winget needs that), bypasses the execution-policy nonsense, and keeps the window open at the end so you can read the results.

**Or, in PowerShell ISE:** open `fulldevkit.ps1`, run as admin, press F5. ISE runs the script content in-session so the execution policy doesn't block it.

Keep `RUN\_ME.bat` and `fulldevkit.ps1` in the same folder.

## Why not just run the .ps1 directly?

Try yourself. There's issues with windows permissions. 

## Notes

* **The build deps are slow.** Python, Java, and especially VS Build Tools (several GB) download quietly with no progress bar. That's not a freeze — go make a coffee.
* **PATH lag.** Right after a fresh install, a tool might not show on PATH in the current session. The script re-reads PATH from the registry to compensate, but if you see a `\[WARN]` at the end, just close the window and run it once more — the second pass settles everything.
* **Adding your own python libs:** edit the `$pipPackageMap` block near the top of the script.

## Turning it into an .exe (optional)

If you'd rather have a single double-clickable binary instead of the .bat + .ps1 pair:

```powershell
Install-Module ps2exe -Scope CurrentUser -Force
Invoke-ps2exe .\\fulldevkit.ps1 .\\fulldevkit.exe -requireAdmin -title "Dev Kit Auditor"
```

`-requireAdmin` bakes the elevation prompt in, so the .exe replaces `RUN\_ME.bat` entirely. Heads up: antivirus sometimes false-flags ps2exe output

## Status legend

When it runs, each line is tagged:

* `\[OK]` = already installed, nothing to do
* `\[MISS]` = wasn't there, attempting install
* `\[FIXED]` = was missing, now installed
* `\[WAIT]` = install in progress
* `\[FAIL]` = couldn't auto-install, manual step printed below it
* `\[WARN]` = non-fatal, usually a PATH thing that a fresh terminal solves

## License

MIT — do whatever you like with it. No warranty; if it installs Webpack on your nan's laptop that's on you.

