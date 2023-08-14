# Define the path to your Terraform plan file
$terraformPlanPath = "path/to/your/terraform/plan/file.tfplan"

# Required Tags
$requiredTags = @("Environment", "Owner", "Purpose")

# Load the Terraform plan JSON
$terraformPlan = terraform show -json $terraformPlanPath | ConvertFrom-Json

# Validate Required Tags
$resourcesWithoutTags = @()

foreach ($resource in $terraformPlan.planned_values.root_module.resources) {
    if ($resource.values.tags -eq $null) {
        $resourcesWithoutTags += $resource.address
    } else {
        $missingTags = $requiredTags | Where-Object { -not $resource.values.tags.ContainsKey($_) }
        if ($missingTags.Count -gt 0) {
            $resourcesWithoutTags += "$($resource.address) (missing tags: $($missingTags -join ', '))"
        }
    }
}

if ($resourcesWithoutTags.Count -eq 0) {
    Write-Host "All resources have required tags defined."
} else {
    Write-Host "Resources without required tags:"
    $resourcesWithoutTags | ForEach-Object { Write-Host $_ }
}
