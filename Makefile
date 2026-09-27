IMAGENES := votacion-vote:1.0 votacion-worker:1.0 votacion-result:1.0
TRIVY    := docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v trivy-cache:/root/.cache/ aquasec/trivy:latest
GITLEAKS := docker run --rm -v $(PWD):/repo zricethezav/gitleaks:latest
HADOLINT := docker run --rm -i hadolint/hadolint hadolint --failure-threshold warning -

.PHONY: ayuda levantar bajar estado logs construir lint secretos vulnerabilidades calidad respaldo pruebas

ayuda: ## Muestra esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

levantar: ## Levanta la aplicación
	cd roxs-voting-app && docker compose up -d --build

bajar: ## Detiene la aplicación sin borrar datos
	cd roxs-voting-app && docker compose stop

estado: ## Estado de los servicios
	cd roxs-voting-app && docker compose ps

logs: ## Sigue los registros
	cd roxs-voting-app && docker compose logs -f --tail 50

construir: ## Construye las imágenes
	cd roxs-voting-app && docker compose build

lint: ## Revisa los Dockerfile con hadolint
	@rc=0; for f in roxs-voting-app/*/Dockerfile; do echo "== $$f"; $(HADOLINT) < $$f || rc=1; done; exit $$rc

secretos: ## Busca secretos filtrados con gitleaks
	$(GITLEAKS) detect --source /repo -v

vulnerabilidades: ## Escanea las imágenes con Trivy
	@for i in $(IMAGENES); do echo "== $$i"; $(TRIVY) image --quiet --scanners vuln --severity CRITICAL --ignore-unfixed --exit-code 1 $$i || exit 1; done

calidad: lint secretos vulnerabilidades ## Ejecuta TODAS las puertas

respaldo: ## Respalda la base de datos
	cd roxs-voting-app && docker compose exec -T postgres pg_dump -U postgres -d votes -Fc > ../votes-$$(date +%Y%m%d-%H%M%S).dump

pruebas: ## Ejecuta las pruebas automáticas
	docker build --target pruebas -t votacion-vote:pruebas roxs-voting-app/vote
	docker run --rm votacion-vote:pruebas

