<#
    renumber-grids.ps1

    Makes every GIF filename in content\grid-works\NN\ match its folder and its
    position on the page, so that <folder> = page and <sequence> = position.

    Order is preserved exactly as it appears now: files are read in the order
    Hugo displays them (filename sort) and renumbered 01..n in that same order.
    Nothing moves on the page; only the names change.

    Renames go through a temporary suffix so that a name already in use by
    another file in the same folder can never collide.

    Dry run:   .\renumber-grids.ps1
    Do it:     .\renumber-grids.ps1 -Apply
#>

param([switch]$Apply)

$root = Join-Path $PSScriptRoot 'content\grid-works'

if (-not (Test-Path $root)) {
    Write-Error "Cannot find $root. Run this from the repository root."
    exit 1
}

$total = 0

foreach ($dir in (Get-ChildItem -LiteralPath $root -Directory | Sort-Object Name)) {

    $series = $dir.Name
    $gifs   = Get-ChildItem -LiteralPath $dir.FullName -Filter *.gif |
              Sort-Object -Property Name -CaseSensitive

    $moves = @()
    for ($i = 0; $i -lt $gifs.Count; $i++) {
        $want = '{0}-{1:d2}.gif' -f $series, ($i + 1)
        if ($gifs[$i].Name -cne $want) {
            $moves += [pscustomobject]@{
                From = $gifs[$i].Name
                To   = $want
                Path = $gifs[$i].FullName
            }
        }
    }

    if ($moves.Count -eq 0) { continue }

    Write-Host ""
    Write-Host ("Series {0}  -  {1} files, {2} to rename" -f $series, $gifs.Count, $moves.Count)
    foreach ($m in $moves) {
        Write-Host ("    {0,-14} ->  {1}" -f $m.From, $m.To)
    }
    $total += $moves.Count

    if ($Apply) {
        # Phase 1: park each file under its target name plus a suffix
        foreach ($m in $moves) {
            Rename-Item -LiteralPath $m.Path -NewName ($m.To + '.renaming')
        }
        # Phase 2: drop the suffix
        foreach ($m in $moves) {
            Rename-Item -LiteralPath (Join-Path $dir.FullName ($m.To + '.renaming')) -NewName $m.To
        }
    }
}

Write-Host ""
if ($total -eq 0) {
    Write-Host "Every file is already correctly numbered."
} elseif ($Apply) {
    Write-Host ("Renamed {0} files." -f $total)
} else {
    Write-Host ("{0} files would be renamed. Re-run with -Apply to do it." -f $total)
}
