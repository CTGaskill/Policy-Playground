# Define your Terraform workspace and plan output file
$TERRAFORM_WORKSPACE = "your_workspace_name"
$PLAN_OUTPUT_FILE = "plan.out"

# Change to the directory containing your Terraform configuration files
Set-Location -Path "C:\path\to\your\terraform\directory"

# Select the appropriate Terraform workspace
terraform workspace select $TERRAFORM_WORKSPACE

# Generate a new plan and save it to the output file
terraform plan -out=$PLAN_OUTPUT_FILE

# Check for drift by comparing the current state to the new plan
terraform show -json > current_state.json
terraform show -json $PLAN_OUTPUT_FILE > planned_state.json

# Function to compare two objects and capture differences
function Compare-DeepDiff {
    param (
        [hashtable] $a,
        [hashtable] $b
    )

    $differences = @{}
    $a.GetEnumerator() | ForEach-Object {
        $key = $_.Key
        $value = $_.Value
        if ($b.ContainsKey($key)) {
            if ($value -ne $b[$key]) {
                $differences[$key] = @{
                    OldValue = $value
                    NewValue = $b[$key]
                }
            }
        }
        else {
            $differences[$key] = @{
                OldValue = $value
                NewValue = $null
            }
        }
    }

    $b.GetEnumerator() | ForEach-Object {
        $key = $_.Key
        if (!$a.ContainsKey($key)) {
            $differences[$key] = @{
                OldValue = $null
                NewValue = $_.Value
            }
        }
    }

    return $differences
}

# Load current and planned states from JSON files
$currentState = Get-Content -Raw -Path "current_state.json" | ConvertFrom-Json
$plannedState = Get-Content -Raw -Path "planned_state.json" | ConvertFrom-Json

# Compare current and planned states
$differences = Compare-DeepDiff -a $currentState -b $plannedState

# Clean up temporary files
Remove-Item "current_state.json"
Remove-Item "planned_state.json"

# Print the result
if ($differences.Count -eq 0) {
    Write-Host "No drift detected."
}
else {
    Write-Host "Drift detected. Detailed differences:"
    $differences | Format-Table -AutoSize | Out-String
}
