# Attestations demos

¡Hola developer 👋🏻! En este repo tengo todas las demos sobre Attestations.


## Recuperar la penúltima imagen que esté disponible en el registro de GitHub Packages:

```bash
source .env

curl -s -H "Authorization: token $GITHUB_TOKEN" \
"https://api.github.com/orgs/returngis/packages/container/tour-of-heroes-api/versions" \
| jq -r '.[2].metadata.container.tags[0]'
```