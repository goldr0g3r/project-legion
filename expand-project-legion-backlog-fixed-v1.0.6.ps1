<#
Project Legion detailed backlog generator v1.0.6

Creates implementation-sized sub-issues, ADR records, Project items, dates, and estimates.
Safe to rerun: exact titles are reused, existing Project items are reused, and ADR files are preserved.
Does NOT create empty pull requests. Pull requests should be created when implementation begins.

Works with older GitHub CLI versions by linking sub-issues through the REST API.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Repository,
    [Parameter(Mandatory)][string]$ProjectOwner,
    [Parameter(Mandatory)][int]$ProjectNumber,
    [ValidateSet("All","M1M2")][string]$Scope = "All",
    [switch]$SkipAdrFiles,
    [switch]$SkipCommit,
    [switch]$SkipPush
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Step([string]$Text){ Write-Host "`n==> $Text" -ForegroundColor Cyan }
function Ok([string]$Text){ Write-Host "[OK] $Text" -ForegroundColor Green }
function Skip([string]$Text){ Write-Host "[SKIP] $Text" -ForegroundColor Yellow }
function Invoke-GhCli([string[]]$A,[switch]$AllowFailure){
    $o = & gh.exe @A 2>&1; $c=$LASTEXITCODE; $t=($o|Out-String).Trim()
    if($c-ne 0 -and -not $AllowFailure){throw "gh failed: gh $($A -join ' ')`n$t"}
    [pscustomobject]@{Code=$c;Text=$t;Lines=@($o)}
}
function ExactIssue([string]$Title){
    # Do not inject the title into a jq expression. Windows PowerShell 5.1 can
    # split native-command arguments containing spaces and embedded quotes.
    # Retrieve JSON and perform the exact-title comparison in PowerShell.
    $r = Invoke-GhCli @(
        "issue", "list",
        "--repo", $Repository,
        "--state", "all",
        "--limit", "500",
        "--json", "number,title,url"
    )

    if ([string]::IsNullOrWhiteSpace($r.Text)) { return $null }

    $parsed = $r.Text | ConvertFrom-Json
    $issues = @()
    if ($null -ne $parsed) { $issues = @($parsed) }

    $match = $issues |
        Where-Object {
            $null -ne $_ -and
            $_.PSObject.Properties.Name -contains "title" -and
            [string]$_.title -ceq $Title
        } |
        Select-Object -First 1

    if ($null -eq $match) { return $null }

    return [pscustomobject]@{
        Number = [int]$match.number
        Url    = [string]$match.url
    }
}
function ProjectItemId([string]$Url){
    $r=Invoke-GhCli @("project","item-list","$ProjectNumber","--owner",$ProjectOwner,"--limit","500","--format","json")
    $j=$r.Text|ConvertFrom-Json
    foreach($i in @($j.items)){
        if(($i.PSObject.Properties.Name -contains "content") -and $null-ne $i.content -and ($i.content.PSObject.Properties.Name -contains "url") -and $i.content.url-eq$Url){return [string]$i.id}
        if(($i.PSObject.Properties.Name -contains "url") -and $i.url-eq$Url){return [string]$i.id}
    }
    return $null
}
function SetDate([string]$Item,[string]$Field,[string]$Date){Invoke-GhCli @("project","item-edit","--id",$Item,"--project-id",$script:ProjectId,"--field-id",$Field,"--date",$Date)|Out-Null}
function SetNum([string]$Item,[string]$Field,[double]$Num){Invoke-GhCli @("project","item-edit","--id",$Item,"--project-id",$script:ProjectId,"--field-id",$Field,"--number",$Num.ToString([Globalization.CultureInfo]::InvariantCulture))|Out-Null}
# Backlog v1.0.3 used broader parent-epic names than the canonical epics
# created by setup-project-legion-fixed.ps1. Resolve those legacy names here
# instead of failing or creating duplicate epics.
$script:ParentEpicAliases = @{
    "EPIC: Requirements, literature review and research protocol" =
        "EPIC: Define requirements, scope, and acceptance criteria"

    "EPIC: Develop and verify underwater plant and current models" =
        "EPIC: Implement and verify the 4-DOF underwater plant"

    "EPIC: Implement baseline station-keeping control" =
        "EPIC: Develop PID station-keeping baseline"

    "EPIC: Implement ROS 2 system architecture" =
        "EPIC: Build ROS 2 architecture, interfaces, logging, and replay"

    "EPIC: Implement STM32 daughter controller and serial interface" =
        "EPIC: Deploy daughter controller and safety state machine to STM32"

    "EPIC: Train and integrate residual reinforcement learning" =
        "EPIC: Develop reinforcement-learning environment and curriculum"

    "EPIC: Closed-loop HIL, fault injection and comparative evaluation" =
        "EPIC: Integrate closed-loop daughter HIL"

    "EPIC: Complete dissertation, reproducibility package and demonstration" =
        "EPIC: Complete dissertation, reproducibility package, and demonstration"
}

function ResolveParentEpic([string]$RequestedTitle){
    $direct = ExactIssue $RequestedTitle
    if($null -ne $direct){
        return [pscustomobject]@{
            RequestedTitle = $RequestedTitle
            ResolvedTitle  = $RequestedTitle
            Issue          = $direct
        }
    }

    if($script:ParentEpicAliases.ContainsKey($RequestedTitle)){
        $canonicalTitle = [string]$script:ParentEpicAliases[$RequestedTitle]
        $canonicalIssue = ExactIssue $canonicalTitle
        if($null -ne $canonicalIssue){
            return [pscustomobject]@{
                RequestedTitle = $RequestedTitle
                ResolvedTitle  = $canonicalTitle
                Issue          = $canonicalIssue
            }
        }
    }

    $r = Invoke-GhCli @(
        "issue", "list",
        "--repo", $Repository,
        "--state", "all",
        "--limit", "500",
        "--label", "type:epic",
        "--json", "title"
    ) -AllowFailure

    $available = @()
    if($r.Code -eq 0 -and -not [string]::IsNullOrWhiteSpace($r.Text)){
        $parsed = $r.Text | ConvertFrom-Json
        foreach($entry in @($parsed)){
            if($null -ne $entry -and
               $entry.PSObject.Properties.Name -contains "title"){
                $available += [string]$entry.title
            }
        }
    }

    $availableText = if($available.Count -gt 0){
        ($available | Sort-Object | ForEach-Object { "  - $_" }) -join [Environment]::NewLine
    } else {
        "  <no issues carrying label type:epic were found>"
    }

    $aliasText = if($script:ParentEpicAliases.ContainsKey($RequestedTitle)){
        "`nConfigured alias target: $($script:ParentEpicAliases[$RequestedTitle])"
    } else { "" }

    throw "Parent epic not found: $RequestedTitle$aliasText`nAvailable epics:`n$availableText"
}

function Get-IssueDatabaseId([int]$IssueNumber){
    $result = Invoke-GhCli @(
        "api",
        "repos/$Repository/issues/$IssueNumber",
        "--jq", ".id"
    )
    if([string]::IsNullOrWhiteSpace($result.Text)){
        throw "Could not obtain the database ID for issue #$IssueNumber."
    }
    return [int64]$result.Text.Trim()
}

function Ensure-SubIssueLink([int]$ParentNumber,[int]$ChildNumber){
    # Query the parent's sub-issue collection. Unlike GET /issues/{child}/parent,
    # this endpoint returns an empty array when no relationship exists instead of 404.
    $listResult = Invoke-GhCli @(
        "api",
        "repos/$Repository/issues/$ParentNumber/sub_issues?per_page=100",
        "-H", "Accept: application/vnd.github+json",
        "-H", "X-GitHub-Api-Version: 2026-03-10"
    )

    $subIssues = @()
    if(-not [string]::IsNullOrWhiteSpace($listResult.Text)){
        $parsedSubIssues = $listResult.Text | ConvertFrom-Json
        if($null -ne $parsedSubIssues){ $subIssues = @($parsedSubIssues) }
    }

    $alreadyLinked = $subIssues |
        Where-Object {
            $null -ne $_ -and
            $_.PSObject.Properties.Name -contains "number" -and
            [int]$_.number -eq $ChildNumber
        } |
        Select-Object -First 1

    if($null -ne $alreadyLinked){
        Skip "Sub-issue relationship already exists: #$ParentNumber -> #$ChildNumber"
        return
    }

    # The add-sub-issue REST endpoint requires the issue database ID, not its number.
    $childDatabaseId = Get-IssueDatabaseId $ChildNumber
    $tempFile = Join-Path $env:TEMP ("legion-sub-issue-" + [guid]::NewGuid().ToString("N") + ".json")
    try{
        $json = @{ sub_issue_id = $childDatabaseId } | ConvertTo-Json -Compress
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($tempFile,$json,$utf8NoBom)

        $addResult = Invoke-GhCli @(
            "api",
            "--method", "POST",
            "-H", "Accept: application/vnd.github+json",
            "-H", "X-GitHub-Api-Version: 2026-03-10",
            "repos/$Repository/issues/$ParentNumber/sub_issues",
            "--input", $tempFile
        ) -AllowFailure

        if($addResult.Code -ne 0){
            # A partial earlier run may have completed the relationship just before
            # a transient error. Re-read before treating the operation as failed.
            $verifyResult = Invoke-GhCli @(
                "api",
                "repos/$Repository/issues/$ParentNumber/sub_issues?per_page=100",
                "-H", "Accept: application/vnd.github+json",
                "-H", "X-GitHub-Api-Version: 2026-03-10"
            )
            $verified = @()
            if(-not [string]::IsNullOrWhiteSpace($verifyResult.Text)){
                $verifiedJson = $verifyResult.Text | ConvertFrom-Json
                if($null -ne $verifiedJson){ $verified = @($verifiedJson) }
            }
            $linkedAfterFailure = $verified |
                Where-Object { $null -ne $_ -and [int]$_.number -eq $ChildNumber } |
                Select-Object -First 1
            if($null -eq $linkedAfterFailure){
                throw "Could not link issue #$ChildNumber under parent #$ParentNumber.`n$($addResult.Text)"
            }
        }
        Ok "Linked sub-issue: #$ParentNumber -> #$ChildNumber"
    }
    finally{
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
}
function EnsureIssue([hashtable]$W){
    $parentResolution = ResolveParentEpic $W.Parent
    $parent = $parentResolution.Issue
    if($parentResolution.RequestedTitle -ne $parentResolution.ResolvedTitle){
        Write-Host "[MAP] Parent epic: $($parentResolution.RequestedTitle)" -ForegroundColor DarkCyan
        Write-Host "   -> $($parentResolution.ResolvedTitle)" -ForegroundColor DarkCyan
    }

    $found = ExactIssue $W.Title
    if($null -eq $found){
        $body = @"
## Objective
$($W.Objective)

## Acceptance criteria
$($W.Criteria | ForEach-Object { "- [ ] $_" } | Out-String)
## Verification
- [ ] Evidence, logs, plots, or test output attached
- [ ] Relevant documentation updated
- [ ] No unrelated changes included

## Planning
- Estimate: $($W.Estimate) working day(s)
- Start: $($W.Start)
- Target: $($W.Target)
- Parent epic: #$($parent.Number)
"@
        # Create a normal issue first. Older gh versions do not support --parent.
        $createResult = Invoke-GhCli @(
            "issue", "create",
            "--repo", $Repository,
            "--title", $W.Title,
            "--body", $body,
            "--label", ($W.Labels -join ","),
            "--milestone", $W.Milestone
        )

        $url = $null
        foreach($line in @($createResult.Lines)){
            $candidate = $line.ToString().Trim()
            if($candidate -match '^https://github[.]com/.+/issues/[0-9]+$'){
                $url = $candidate
            }
        }
        if([string]::IsNullOrWhiteSpace($url)){
            # Fall back to exact-title lookup instead of assuming a particular gh output format.
            $created = ExactIssue $W.Title
            if($null -eq $created){
                throw "Issue creation succeeded, but the created issue could not be located: $($W.Title)"
            }
            $found = $created
        }
        else{
            $found = [pscustomobject]@{
                Number = [int](($url -split '/')[-1])
                Url = $url
            }
        }
        Ok "Created #$($found.Number): $($W.Title)"
    }
    else{
        Skip "Issue exists #$($found.Number): $($W.Title)"
    }

    Ensure-SubIssueLink -ParentNumber $parent.Number -ChildNumber $found.Number

    $item = ProjectItemId $found.Url
    if([string]::IsNullOrWhiteSpace($item)){
        Invoke-GhCli @(
            "project", "item-add", "$ProjectNumber",
            "--owner", $ProjectOwner,
            "--url", $found.Url
        ) | Out-Null
        Start-Sleep -Milliseconds 500
        $item = ProjectItemId $found.Url
        if([string]::IsNullOrWhiteSpace($item)){
            throw "Issue was added to the Project, but its Project item ID could not be retrieved: $($W.Title)"
        }
        Ok "Added to Project: $($W.Title)"
    }

    SetDate $item $script:StartField $W.Start
    SetDate $item $script:TargetField $W.Target
    SetNum $item $script:EstimateField $W.Estimate
}
function AdrFile([hashtable]$A,[int]$Index){
    if($SkipAdrFiles){return}
    $dir="docs/architecture/decisions"; New-Item -ItemType Directory -Path $dir -Force|Out-Null
    $slug=($A.Title.ToLower() -replace '[^a-z0-9]+','-').Trim('-'); $file=Join-Path $dir (("{0:D4}-{1}.md" -f $Index,$slug))
    if(Test-Path $file){Skip "ADR file exists: $file";return}
@"
# ADR-$('{0:D4}' -f $Index): $($A.Title)

- Status: Proposed
- Date: 2026-07-20
- Related epic: $($A.Parent)

## Context
$($A.Context)

## Options considered
1. Option A
2. Option B
3. Alternative or hybrid approach

## Decision
To be completed and changed from Proposed to Accepted after review.

## Rationale
Record evidence, constraints, and trade-offs here.

## Consequences
- Positive consequences
- Negative consequences
- Follow-up actions

## Validation
Document the tests or measurements that validate this decision.
"@ | Set-Content $file -Encoding UTF8
    Ok "Created ADR file: $file"
}

try{
    Write-Host "Project Legion backlog generator v1.0.6" -ForegroundColor DarkGray
    Step "Checking prerequisites"
    if (-not (Get-Command gh.exe -ErrorAction SilentlyContinue)) { throw "gh.exe was not found in PATH." }
    if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) { throw "git.exe was not found in PATH." }
    Invoke-GhCli @("auth","status") | Out-Null
    Invoke-GhCli @("repo","view",$Repository,"--json","nameWithOwner") | Out-Null
    $pv=Invoke-GhCli @("project","view","$ProjectNumber","--owner",$ProjectOwner,"--format","json"); $pj=$pv.Text|ConvertFrom-Json; $script:ProjectId=[string]$pj.id
    $fr=Invoke-GhCli @("project","field-list","$ProjectNumber","--owner",$ProjectOwner,"--format","json"); $fj=$fr.Text|ConvertFrom-Json
    $script:StartField=[string](($fj.fields|Where-Object{$_.name-eq"Start Date"}|Select-Object -First 1).id)
    $script:TargetField=[string](($fj.fields|Where-Object{$_.name-eq"Target Date"}|Select-Object -First 1).id)
    $script:EstimateField=[string](($fj.fields|Where-Object{$_.name-eq"Estimate Days"}|Select-Object -First 1).id)
    if([string]::IsNullOrWhiteSpace($script:StartField)-or[string]::IsNullOrWhiteSpace($script:TargetField)-or[string]::IsNullOrWhiteSpace($script:EstimateField)){throw "Required Project fields are missing."}
    Ok "Repository and Project are accessible"

    Step "Ensuring additional labels"
    $labs=@(
      @{N="type:spike";C="BFD4F2";D="Time-boxed technical investigation"},@{N="type:validation";C="0E8A16";D="Verification or validation activity"},
      @{N="type:docs";C="0075CA";D="Documentation work"},@{N="adr";C="FEF2C0";D="Architecture decision record"}
    )
    foreach($l in $labs){Invoke-GhCli @("label","create",$l.N,"--repo",$Repository,"--color",$l.C,"--description",$l.D,"--force")|Out-Null}

    $work=@(
      @{Title="TASK: Freeze Version 1 project scope";Parent="EPIC: Requirements, literature review and research protocol";Milestone="M1 - Foundation and 4-DOF Baseline";Labels=@("type:task","area:research");Start="2026-07-20";Target="2026-07-21";Estimate=2;Objective="Define included and deferred capabilities.";Criteria=@("Version 1 inclusions listed","Deferred features listed","Scope approved")},
      @{Title="TASK: Define research questions and hypotheses";Parent="EPIC: Requirements, literature review and research protocol";Milestone="M1 - Foundation and 4-DOF Baseline";Labels=@("type:task","area:research");Start="2026-07-22";Target="2026-07-23";Estimate=2;Objective="Create measurable research questions.";Criteria=@("Questions map to metrics","Hypotheses are falsifiable")},
      @{Title="TASK: Create literature review matrix";Parent="EPIC: Requirements, literature review and research protocol";Milestone="M1 - Foundation and 4-DOF Baseline";Labels=@("type:task","area:research");Start="2026-07-24";Target="2026-07-28";Estimate=3;Objective="Structure the literature evidence base.";Criteria=@("At least 25 sources categorized","Research gaps recorded")},
      @{Title="TASK: Define station-keeping success criteria";Parent="EPIC: Requirements, literature review and research protocol";Milestone="M1 - Foundation and 4-DOF Baseline";Labels=@("type:task","area:research");Start="2026-07-29";Target="2026-07-30";Estimate=2;Objective="Freeze measurable pass and failure limits.";Criteria=@("Position and attitude tolerances defined","Failure conditions documented")},
      @{Title="TASK: Define experiment metrics and seed policy";Parent="EPIC: Requirements, literature review and research protocol";Milestone="M1 - Foundation and 4-DOF Baseline";Labels=@("type:task","area:testing");Start="2026-07-31";Target="2026-08-03";Estimate=2;Objective="Make experiments reproducible.";Criteria=@("Metrics equations documented","Training and evaluation seeds separated")},
      @{Title="TASK: Create project risk register";Parent="EPIC: Requirements, literature review and research protocol";Milestone="M1 - Foundation and 4-DOF Baseline";Labels=@("type:task","area:safety");Start="2026-08-04";Target="2026-08-05";Estimate=2;Objective="Identify schedule and technical risks.";Criteria=@("Risks scored","Mitigations and decision gates assigned")},
      @{Title="TASK: Freeze NED coordinate and sign convention";Parent="EPIC: Develop and verify underwater plant and current models";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:modeling");Start="2026-08-20";Target="2026-08-21";Estimate=2;Objective="Define all frames and signs.";Criteria=@("State vector documented","Frame transforms unit-tested")},
      @{Title="TASK: Define mother and daughter nominal parameters";Parent="EPIC: Develop and verify underwater plant and current models";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:modeling");Start="2026-08-22";Target="2026-08-24";Estimate=2;Objective="Create versioned plant parameter sets.";Criteria=@("Mass and inertia defined","Buoyancy and centers defined","Sources recorded")},
      @{Title="TASK: Implement six-DOF kinematics";Parent="EPIC: Develop and verify underwater plant and current models";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:modeling");Start="2026-08-25";Target="2026-08-27";Estimate=3;Objective="Implement pose-rate transformation.";Criteria=@("Quaternion normalization handled","Known rotations tested")},
      @{Title="TASK: Implement rigid-body and added-mass matrices";Parent="EPIC: Develop and verify underwater plant and current models";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:modeling");Start="2026-08-28";Target="2026-09-01";Estimate=3;Objective="Implement inertia representation.";Criteria=@("Matrices dimensionally valid","Symmetry checks pass")},
      @{Title="TASK: Implement Coriolis and centripetal terms";Parent="EPIC: Develop and verify underwater plant and current models";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:modeling");Start="2026-09-02";Target="2026-09-04";Estimate=3;Objective="Add nonlinear velocity coupling.";Criteria=@("Zero-velocity output verified","Energy consistency checked")},
      @{Title="TASK: Implement linear and quadratic damping";Parent="EPIC: Develop and verify underwater plant and current models";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:modeling");Start="2026-09-05";Target="2026-09-07";Estimate=2;Objective="Model hydrodynamic drag.";Criteria=@("Drag opposes relative motion","Coefficients configurable")},
      @{Title="TASK: Implement hydrostatic restoring forces";Parent="EPIC: Develop and verify underwater plant and current models";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:modeling");Start="2026-09-08";Target="2026-09-09";Estimate=2;Objective="Model gravity and buoyancy.";Criteria=@("Neutral equilibrium verified","Roll and pitch restoration verified")},
      @{Title="TASK: Implement thruster force model and allocation matrix";Parent="EPIC: Develop and verify underwater plant and current models";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:controls");Start="2026-09-10";Target="2026-09-12";Estimate=3;Objective="Map commands to generalized forces.";Criteria=@("All thruster directions tested","Saturation represented")},
      @{Title="TASK: Implement constant and Gauss-Markov currents";Parent="EPIC: Develop and verify underwater plant and current models";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:modeling");Start="2026-09-13";Target="2026-09-15";Estimate=3;Objective="Provide deterministic and stochastic disturbances.";Criteria=@("Seeded runs repeat","Current remains bounded")},
      @{Title="VALIDATION: Verify equilibrium, signs, and free decay";Parent="EPIC: Develop and verify underwater plant and current models";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:validation","area:testing");Start="2026-09-16";Target="2026-09-19";Estimate=3;Objective="Validate core plant behavior.";Criteria=@("Equilibrium test passes","Impulse signs correct","Free decay produces expected damping")},
      @{Title="TASK: Define controller loop rates and interfaces";Parent="EPIC: Implement baseline station-keeping control";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:controls");Start="2026-08-20";Target="2026-08-21";Estimate=2;Objective="Freeze controller timing and I/O.";Criteria=@("Rates documented","Signal units and frames explicit")},
      @{Title="TASK: Implement position and attitude PID";Parent="EPIC: Implement baseline station-keeping control";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:controls");Start="2026-08-22";Target="2026-08-26";Estimate=3;Objective="Create baseline six-axis controller.";Criteria=@("Each axis independently testable","Reset behavior defined")},
      @{Title="TASK: Add anti-windup and derivative filtering";Parent="EPIC: Implement baseline station-keeping control";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:controls");Start="2026-08-27";Target="2026-08-29";Estimate=2;Objective="Improve constrained response.";Criteria=@("Integrator remains bounded","Derivative noise controlled")},
      @{Title="TASK: Add output saturation and slew limiting";Parent="EPIC: Implement baseline station-keeping control";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:controls");Start="2026-08-30";Target="2026-09-01";Estimate=2;Objective="Protect actuator commands.";Criteria=@("Limits configurable","No discontinuous command jumps")},
      @{Title="TASK: Tune still-water PID baseline";Parent="EPIC: Implement baseline station-keeping control";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:controls");Start="2026-09-02";Target="2026-09-06";Estimate=3;Objective="Establish nominal gains.";Criteria=@("Settling targets met","Overshoot documented")},
      @{Title="TASK: Implement current disturbance compensation";Parent="EPIC: Implement baseline station-keeping control";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:controls");Start="2026-09-07";Target="2026-09-11";Estimate=3;Objective="Add estimated disturbance feedforward.";Criteria=@("Can be enabled independently","Improvement measured")},
      @{Title="VALIDATION: Benchmark PID under randomized currents";Parent="EPIC: Implement baseline station-keeping control";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:validation","area:testing");Start="2026-09-12";Target="2026-09-19";Estimate=4;Objective="Create baseline results for RL comparison.";Criteria=@("At least 30 seeds executed","Accuracy and effort reported")},
      @{Title="TASK: Define ROS 2 packages, topics, and message contracts";Parent="EPIC: Implement ROS 2 system architecture";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:ros2");Start="2026-08-20";Target="2026-08-23";Estimate=3;Objective="Freeze ROS 2 interfaces.";Criteria=@("Namespaces documented","QoS assigned","Units and frames explicit")},
      @{Title="TASK: Implement TF tree and frame conversion tests";Parent="EPIC: Implement ROS 2 system architecture";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:ros2");Start="2026-08-24";Target="2026-08-27";Estimate=3;Objective="Provide consistent transforms.";Criteria=@("Mother and daughter trees valid","NED conversion tested")},
      @{Title="TASK: Implement mother and daughter plant adapters";Parent="EPIC: Implement ROS 2 system architecture";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:ros2");Start="2026-08-28";Target="2026-09-02";Estimate=4;Objective="Expose plants through ROS 2.";Criteria=@("Command and state interfaces work","Timestamps are consistent")},
      @{Title="TASK: Implement mission and scenario managers";Parent="EPIC: Implement ROS 2 system architecture";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:ros2");Start="2026-09-03";Target="2026-09-07";Estimate=3;Objective="Automate targets and disturbances.";Criteria=@("Scenarios load from config","Runs have unique IDs")},
      @{Title="TASK: Implement rosbag2 logging and diagnostics";Parent="EPIC: Implement ROS 2 system architecture";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:ros2");Start="2026-09-08";Target="2026-09-12";Estimate=3;Objective="Record all evidence.";Criteria=@("Required topics recorded","Fault diagnostics visible")},
      @{Title="TASK: Create single-command experiment launch";Parent="EPIC: Implement ROS 2 system architecture";Milestone="M2 - 6-DOF Modeling and ROS 2";Labels=@("type:task","area:ros2");Start="2026-09-13";Target="2026-09-19";Estimate=4;Objective="Make experiments reproducible.";Criteria=@("One command launches stack","Configuration is archived")},
      @{Title="TASK: Define framed UART protocol and test vectors";Parent="EPIC: Implement STM32 daughter controller and serial interface";Milestone="M3 - STM32 and PIL";Labels=@("type:task","area:communication");Start="2026-09-20";Target="2026-09-23";Estimate=3;Objective="Specify byte-level communication.";Criteria=@("Packet schema versioned","Golden vectors committed")},
      @{Title="TASK: Implement STM32 packet encoder and decoder";Parent="EPIC: Implement STM32 daughter controller and serial interface";Milestone="M3 - STM32 and PIL";Labels=@("type:task","area:embedded");Start="2026-09-24";Target="2026-09-28";Estimate=3;Objective="Implement streaming protocol handling.";Criteria=@("Split packets handled","Malformed packets rejected")},
      @{Title="TASK: Implement CRC, sequence, and stale-command checks";Parent="EPIC: Implement STM32 daughter controller and serial interface";Milestone="M3 - STM32 and PIL";Labels=@("type:task","area:safety");Start="2026-09-29";Target="2026-10-01";Estimate=3;Objective="Reject unsafe communication.";Criteria=@("CRC failures logged","Replay and stale packets rejected")},
      @{Title="TASK: Implement fixed-rate PID and allocation loop on STM32";Parent="EPIC: Implement STM32 daughter controller and serial interface";Milestone="M3 - STM32 and PIL";Labels=@("type:task","area:embedded");Start="2026-10-02";Target="2026-10-07";Estimate=4;Objective="Deploy deterministic daughter control.";Criteria=@("Loop frequency measured","Outputs match reference")},
      @{Title="TASK: Implement watchdog and arm-disarm state machine";Parent="EPIC: Implement STM32 daughter controller and serial interface";Milestone="M3 - STM32 and PIL";Labels=@("type:task","area:safety");Start="2026-10-08";Target="2026-10-11";Estimate=3;Objective="Provide MCU safety supervision.";Criteria=@("Neutral startup","Timeout disarms","Fault reset controlled")},
      @{Title="VALIDATION: Run STM32 PIL numerical equivalence";Parent="EPIC: Implement STM32 daughter controller and serial interface";Milestone="M3 - STM32 and PIL";Labels=@("type:validation","area:testing");Start="2026-10-12";Target="2026-10-15";Estimate=3;Objective="Compare generated target execution to model.";Criteria=@("Tolerance defined","Differences reported")},
      @{Title="VALIDATION: Measure MCU WCET, memory, and serial latency";Parent="EPIC: Implement STM32 daughter controller and serial interface";Milestone="M3 - STM32 and PIL";Labels=@("type:validation","area:testing");Start="2026-10-16";Target="2026-10-19";Estimate=3;Objective="Establish resource margins.";Criteria=@("Worst-case loop time reported","Stack and flash reported","Latency percentiles reported")},
      @{Title="TASK: Define RL observations, actions, and limits";Parent="EPIC: Train and integrate residual reinforcement learning";Milestone="M4 - Reinforcement Learning";Labels=@("type:task","area:rl");Start="2026-10-20";Target="2026-10-23";Estimate=3;Objective="Freeze the learning interface.";Criteria=@("All values normalized","Action authority bounded")},
      @{Title="TASK: Implement reward and termination logic";Parent="EPIC: Train and integrate residual reinforcement learning";Milestone="M4 - Reinforcement Learning";Labels=@("type:task","area:rl");Start="2026-10-24";Target="2026-10-27";Estimate=3;Objective="Create safety-aware objective.";Criteria=@("Reward components logged","Unsafe states terminate")},
      @{Title="TASK: Implement deterministic RL environment reset";Parent="EPIC: Train and integrate residual reinforcement learning";Milestone="M4 - Reinforcement Learning";Labels=@("type:task","area:rl");Start="2026-10-28";Target="2026-10-31";Estimate=3;Objective="Guarantee reproducible episodes.";Criteria=@("Same seed reproduces trajectory","Config snapshot saved")},
      @{Title="TASK: Implement curriculum and domain randomization";Parent="EPIC: Train and integrate residual reinforcement learning";Milestone="M4 - Reinforcement Learning";Labels=@("type:task","area:rl");Start="2026-11-01";Target="2026-11-05";Estimate=4;Objective="Improve robustness progressively.";Criteria=@("Curriculum levels configurable","Parameter distributions documented")},
      @{Title="EXPERIMENT: Train PPO baseline";Parent="EPIC: Train and integrate residual reinforcement learning";Milestone="M4 - Reinforcement Learning";Labels=@("type:experiment","area:rl");Start="2026-11-06";Target="2026-11-11";Estimate=4;Objective="Train initial policy.";Criteria=@("Training curves saved","Best and final checkpoints retained")},
      @{Title="TASK: Integrate bounded residual RL over PID";Parent="EPIC: Train and integrate residual reinforcement learning";Milestone="M4 - Reinforcement Learning";Labels=@("type:task","area:controls");Start="2026-11-12";Target="2026-11-15";Estimate=3;Objective="Combine learning with deterministic control.";Criteria=@("Residual can be disabled","Authority limit enforced")},
      @{Title="VALIDATION: Evaluate RL on held-out seeds";Parent="EPIC: Train and integrate residual reinforcement learning";Milestone="M4 - Reinforcement Learning";Labels=@("type:validation","area:testing");Start="2026-11-16";Target="2026-11-19";Estimate=3;Objective="Test generalization.";Criteria=@("No training seeds reused","Failure rate and confidence intervals reported")},
      @{Title="TASK: Establish real-time PC-to-STM32 HIL loop";Parent="EPIC: Closed-loop HIL, fault injection and comparative evaluation";Milestone="M5 - HIL and Evaluation";Labels=@("type:task","area:testing");Start="2026-11-20";Target="2026-11-24";Estimate=3;Objective="Close the daughter loop through physical MCU.";Criteria=@("Stable nominal loop","Timing logged")},
      @{Title="EXPERIMENT: Perform latency and jitter sweeps";Parent="EPIC: Closed-loop HIL, fault injection and comparative evaluation";Milestone="M5 - HIL and Evaluation";Labels=@("type:experiment","area:testing");Start="2026-11-25";Target="2026-11-28";Estimate=3;Objective="Measure timing robustness.";Criteria=@("Multiple latency levels tested","Failure boundary identified")},
      @{Title="EXPERIMENT: Perform packet-loss and corruption sweeps";Parent="EPIC: Closed-loop HIL, fault injection and comparative evaluation";Milestone="M5 - HIL and Evaluation";Labels=@("type:experiment","area:communication");Start="2026-11-29";Target="2026-12-02";Estimate=3;Objective="Measure link fault tolerance.";Criteria=@("Loss rates tested","CRC recovery verified")},
      @{Title="EXPERIMENT: Inject sensor noise and bias";Parent="EPIC: Closed-loop HIL, fault injection and comparative evaluation";Milestone="M5 - HIL and Evaluation";Labels=@("type:experiment","area:testing");Start="2026-12-03";Target="2026-12-05";Estimate=2;Objective="Measure estimator and controller robustness.";Criteria=@("Noise levels documented","Performance degradation plotted")},
      @{Title="EXPERIMENT: Evaluate hydrodynamic uncertainty";Parent="EPIC: Closed-loop HIL, fault injection and comparative evaluation";Milestone="M5 - HIL and Evaluation";Labels=@("type:experiment","area:testing");Start="2026-12-06";Target="2026-12-09";Estimate=3;Objective="Evaluate mass and damping mismatch.";Criteria=@("Held-out parameter ranges used","Failures recorded")},
      @{Title="VALIDATION: Verify RL timeout and PID fallback";Parent="EPIC: Closed-loop HIL, fault injection and comparative evaluation";Milestone="M5 - HIL and Evaluation";Labels=@("type:validation","area:safety");Start="2026-12-10";Target="2026-12-12";Estimate=2;Objective="Prove safe degraded behavior.";Criteria=@("RL disconnect injected","PID remains bounded")},
      @{Title="EXPERIMENT: Run final Monte Carlo controller comparison";Parent="EPIC: Closed-loop HIL, fault injection and comparative evaluation";Milestone="M5 - HIL and Evaluation";Labels=@("type:experiment","area:testing");Start="2026-12-13";Target="2026-12-19";Estimate=5;Objective="Produce final statistical comparison.";Criteria=@("Identical seeds used","Confidence intervals generated","All failures included")},
      @{Title="DOCS: Write architecture and modeling chapters";Parent="EPIC: Complete dissertation, reproducibility package and demonstration";Milestone="M6 - Dissertation and Demonstration";Labels=@("type:docs","area:thesis");Start="2026-10-20";Target="2026-11-20";Estimate=12;Objective="Document system and equations.";Criteria=@("Figures numbered","Assumptions and limitations stated")},
      @{Title="DOCS: Write control and RL methodology chapters";Parent="EPIC: Complete dissertation, reproducibility package and demonstration";Milestone="M6 - Dissertation and Demonstration";Labels=@("type:docs","area:thesis");Start="2026-11-01";Target="2026-12-05";Estimate=14;Objective="Document controllers and training.";Criteria=@("Algorithms reproducible","Hyperparameters included")},
      @{Title="DOCS: Write HIL methodology and safety chapter";Parent="EPIC: Complete dissertation, reproducibility package and demonstration";Milestone="M6 - Dissertation and Demonstration";Labels=@("type:docs","area:thesis");Start="2026-11-20";Target="2026-12-15";Estimate=9;Objective="Document experimental platform.";Criteria=@("Timing architecture included","Fault handling documented")},
      @{Title="DOCS: Generate final plots and results chapter";Parent="EPIC: Complete dissertation, reproducibility package and demonstration";Milestone="M6 - Dissertation and Demonstration";Labels=@("type:docs","area:thesis");Start="2026-12-20";Target="2027-01-05";Estimate=10;Objective="Present final evidence.";Criteria=@("Plots generated from scripts","Statistics interpreted")},
      @{Title="TASK: Create tagged reproducibility release";Parent="EPIC: Complete dissertation, reproducibility package and demonstration";Milestone="M6 - Dissertation and Demonstration";Labels=@("type:task","area:docs");Start="2027-01-06";Target="2027-01-10";Estimate=4;Objective="Freeze code, configs, and instructions.";Criteria=@("Release tagged","Clean-machine procedure documented")},
      @{Title="TASK: Prepare and rehearse final demonstration";Parent="EPIC: Complete dissertation, reproducibility package and demonstration";Milestone="M6 - Dissertation and Demonstration";Labels=@("type:task","area:thesis");Start="2027-01-11";Target="2027-01-16";Estimate=4;Objective="Prepare stable presentation flow.";Criteria=@("Demo script timed","Fallback recording available")},
      @{Title="DOCS: Complete dissertation submission package";Parent="EPIC: Complete dissertation, reproducibility package and demonstration";Milestone="M6 - Dissertation and Demonstration";Labels=@("type:docs","area:thesis");Start="2027-01-17";Target="2027-01-19";Estimate=3;Objective="Complete final submission.";Criteria=@("Formatting checked","Artifacts archived","Submission checklist complete")}
    )
    if($Scope-eq"M1M2"){$work=@($work|Where-Object{$_.Milestone -like "M1*" -or $_.Milestone -like "M2*"})}
    Step "Creating or updating $($work.Count) detailed work items"
    foreach($w in $work){EnsureIssue $w}

    $adrs=@(
      @{Title="Use a monorepo";Parent="EPIC: Requirements, literature review and research protocol";Context="The simulation, firmware, ROS 2 interfaces, experiments, and thesis artifacts require synchronized versioning."},
      @{Title="Use NED as the primary model frame";Parent="EPIC: Develop and verify underwater plant and current models";Context="Marine equations and ROS visualization require an explicit, consistent frame policy."},
      @{Title="Use a Fossen-based six-DOF plant";Parent="EPIC: Develop and verify underwater plant and current models";Context="The dissertation requires a defensible nonlinear underwater vehicle formulation."},
      @{Title="Select the authoritative plant implementation";Parent="EPIC: Develop and verify underwater plant and current models";Context="MATLAB, Simulink, and Python implementations must not silently diverge."},
      @{Title="Use PID as the deterministic baseline";Parent="EPIC: Implement baseline station-keeping control";Context="RL performance must be compared against a stable and explainable controller."},
      @{Title="Use residual RL instead of unrestricted end-to-end RL";Parent="EPIC: Train and integrate residual reinforcement learning";Context="The six-month schedule and HIL safety requirements favor bounded learning authority."},
      @{Title="Run RL inference on the PC";Parent="EPIC: Train and integrate residual reinforcement learning";Context="Model iteration and framework support are stronger on the host than on STM32."},
      @{Title="Run daughter PID and safety logic on STM32";Parent="EPIC: Implement STM32 daughter controller and serial interface";Context="The daughter loop must remain safe when host inference or communications fail."},
      @{Title="Use ROS 2 for orchestration, not the MCU hard real-time loop";Parent="EPIC: Implement ROS 2 system architecture";Context="Middleware scheduling should not determine the fastest embedded feedback loop."},
      @{Title="Use framed UART before RS-485";Parent="EPIC: Implement STM32 daughter controller and serial interface";Context="Protocol correctness should be separated from the later differential physical layer."},
      @{Title="Use PPO as the initial RL algorithm";Parent="EPIC: Train and integrate residual reinforcement learning";Context="The first implementation should prioritize training stability and debuggability."},
      @{Title="Use domain randomization for robustness";Parent="EPIC: Train and integrate residual reinforcement learning";Context="The policy must tolerate uncertain currents and hydrodynamic coefficients."},
      @{Title="Define SIL PIL and HIL boundaries";Parent="EPIC: Closed-loop HIL, fault injection and comparative evaluation";Context="Each verification level needs an unambiguous execution boundary."},
      @{Title="Version experiment configurations and random seeds";Parent="EPIC: Requirements, literature review and research protocol";Context="Dissertation results must be reproducible and auditable."},
      @{Title="Use automatic RL-to-PID fallback";Parent="EPIC: Closed-loop HIL, fault injection and comparative evaluation";Context="A stale or invalid learning output must not remove deterministic control."}
    )
    Step "Creating ADR files and decision issues"
    $n=1
    foreach($a in $adrs){
      AdrFile $a $n
      $w=@{Title=("ADR-{0:D4}: {1}" -f $n,$a.Title);Parent=$a.Parent;Milestone="M1 - Foundation and 4-DOF Baseline";Labels=@("type:decision","adr");Start="2026-07-20";Target="2026-08-19";Estimate=1;Objective=$a.Context;Criteria=@("Options and trade-offs documented","Decision status recorded","Consequences and validation identified")}
      EnsureIssue $w; $n++
    }

    Step "Creating pull request template"
    New-Item -ItemType Directory -Path ".github" -Force|Out-Null
    $pr=".github/pull_request_template.md"
    if(-not(Test-Path $pr)){
@"
## Summary

## Related issue
Closes #

## Verification
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Frames and units verified
- [ ] Documentation updated

## Evidence

## Risks

## Reproduction
"@|Set-Content $pr -Encoding UTF8
      Ok "Created $pr"
    }else{Skip "PR template already exists"}

    if(-not $SkipCommit){
      $s=& git status --porcelain
      if(-not[string]::IsNullOrWhiteSpace(($s|Out-String))){& git add .;& git commit -m "docs: add Project Legion ADRs and planning templates";if($LASTEXITCODE-ne 0){throw "git commit failed"};if(-not$SkipPush){& git push;if($LASTEXITCODE-ne 0){Write-Warning "Push failed; run git push manually."}}}
    }
    Step "Completed"
    Write-Host "Detailed work items processed: $($work.Count)"
    Write-Host "ADRs processed: $($adrs.Count)"
    Write-Host "No empty pull requests were created. Create each PR from its implementation branch."
}catch{Write-Host "`n[FAILED] $($_.Exception.Message)" -ForegroundColor Red;if($_.InvocationInfo.ScriptLineNumber){Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red};exit 1}
