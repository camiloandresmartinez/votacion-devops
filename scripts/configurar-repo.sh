#!/bin/bash
# Configuración del repositorio. Idempotente: se puede correr varias veces.
set -Eeuo pipefail

REPO=camiloandresmartinez/votacion-devops

echo "→ Protegiendo la rama master"
gh api -X PUT "repos/$REPO/branches/master/protection" --input - <<'EOF'
{
  "required_status_checks": { "strict": true, "contexts": ["Puertas de calidad"] },
  "enforce_admins": true,
  "required_pull_request_reviews": null,
  "restrictions": null
}
EOF

echo "→ Permisos mínimos para los workflows"
gh api -X PUT "repos/$REPO/actions/permissions/workflow" -f default_workflow_permissions=read

echo "✅ Listo. Pendiente a mano: el secreto ANSIBLE_VAULT_PASSWORD (gh secret set)"
