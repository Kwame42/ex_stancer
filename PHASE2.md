# Phase 2 — Métaprogrammation et Génération Automatique

## Vue d'ensemble

La Phase 2 introduit un système de génération automatique de fonctions API à partir de la spécification OpenAPI de Stancer.

### Composants

#### 1. **Stancer.OpenAPILoader** (`lib/stancer/openapi_loader.ex`)

Charge et parse la spécification OpenAPI depuis https://docs.stancer.com/api/openapi.json

**Fonctions principales:**
- `load_spec/0` — Charge la spec et retourne `{:ok, spec}` ou `{:error, reason}`
- `load_spec!/0` — Charge la spec ou lève une exception
- `extract_endpoints/1` — Extrait tous les endpoints de la spec
- `param_to_elixir_type/1` — Convertit les types OpenAPI en types Elixir

**Exemple:**
```elixir
{:ok, spec} = Stancer.OpenAPILoader.load_spec()
endpoints = Stancer.OpenAPILoader.extract_endpoints(spec)
```

#### 2. **Stancer.OpenAPIGenerator** (`lib/stancer/openapi_generator.ex`)

Génère le code AST pour les fonctions API à partir des endpoints OpenAPI.

**Fonctions principales:**
- `generate_api_functions/1` — Génère une liste de fonctions AST pour tous les endpoints
- Chaque fonction inclut:
  - Documentation extraite de la spec
  - Spécifications de type (`@spec`)
  - Logique d'appel HTTP appropriée

**Exemple interne:**
```elixir
functions = Stancer.OpenAPIGenerator.generate_api_functions(spec)
# functions est une liste de AST quoted qui peuvent être unquote dans le module
```

#### 3. **Stancer.DynamicAPI** (`lib/stancer/dynamic_api.ex`)

Fournit une API de haut niveau pour invoquer dynamiquement les endpoints Stancer.

**Fonctions principales:**
- `get_endpoints/0` — Liste tous les endpoints disponibles
- `get_endpoint_info/1` — Info détaillée sur un endpoint spécifique
- `call/2` — Appelle un endpoint par operation_id avec des paramètres
- `list_operations/0` — Liste toutes les opérations disponibles
- `get_operations_by_resource/0` — Opérations groupées par ressource
- `print_api_docs/0` — Affiche la documentation formatée

**Exemples:**
```elixir
# Lister tous les endpoints
{:ok, endpoints} = Stancer.DynamicAPI.get_endpoints()

# Appeler un endpoint dynamiquement
{:ok, token} = Stancer.DynamicAPI.call("post_tokens", %{
  "card" => %{
    "number" => "4111111111111111",
    "exp_month" => 12,
    "exp_year" => 2026,
    "cvc" => "123"
  }
})

# Imprimer la documentation
Stancer.DynamicAPI.print_api_docs()

# Grouper les opérations par ressource
{:ok, operations} = Stancer.DynamicAPI.get_operations_by_resource()
```

## Architecture

```
Spec OpenAPI (https://docs.stancer.com/api/openapi.json)
    ↓
Stancer.OpenAPILoader.load_spec()
    ↓
Stancer.OpenAPILoader.extract_endpoints()
    ↓
Stancer.OpenAPIGenerator.generate_api_functions()
    ↓
[AST quoted functions]
    ↓
Stancer module (unquote) — Fonctions manuelles (fallback)
Stancer.DynamicAPI — Appels dynamiques
```

## Features

### 1. **Génération de Documentation**

Chaque fonction générée inclut:
- Méthode HTTP et chemin
- Description de OpenAPI
- Liste des paramètres avec types et descriptions
- Type de réponse (`{:ok, map()} | {:error, term()}`)

**Exemple:**
```elixir
@doc """
POST /tokens

Tokenize a card and return a card token.

Parameters:
- `card_data`: Map containing card information

Returns: `{:ok, response_data}` on success or `{:error, reason}` on failure
"""
@spec tokenize_card(map()) :: {:ok, map()} | {:error, term()}
def tokenize_card(data) when is_map(data) do
  Stancer.request(:post, "/tokens", data)
end
```

### 2. **Spécifications de Type**

Toutes les fonctions ont des `@spec` générées automatiquement basées sur:
- Les paramètres de la spec OpenAPI
- Le type de réponse standard Stancer (`{:ok, map()} | {:error, term()}`)

### 3. **Appels Dynamiques**

Via `Stancer.DynamicAPI.call/2`, on peut invoquer n'importe quel endpoint:
```elixir
Stancer.DynamicAPI.call(operation_id, params)
```

## Utilisation

### Option 1: Fonctions manuelles (recommandé pour la prod)

```elixir
# Les fonctions de base sont toujours disponibles
{:ok, token} = Stancer.tokenize_card(%{
  "card" => %{"number" => "4111...", ...}
})
```

### Option 2: Appels dynamiques (flexibilité)

```elixir
# Appeler n'importe quel endpoint sans avoir à générer les fonctions
{:ok, result} = Stancer.DynamicAPI.call("post_tokens", %{
  "card" => %{...}
})
```

### Option 3: Explorer l'API

```elixir
# Voir tous les endpoints
{:ok, endpoints} = Stancer.DynamicAPI.get_endpoints()

# Imprimer la documentation
Stancer.DynamicAPI.print_api_docs()

# Chercher un endpoint spécifique
{:ok, endpoint} = Stancer.DynamicAPI.get_endpoint_info("post_tokens")
```

## Améliorations Futures

### Phase 2.1: Compilation statique

Générer les fonctions au temps de compilation au lieu de runtime (pour plus de performance).

```elixir
# Dans lib/stancer.ex - macro qui génère les fonctions
@openapi_spec load_spec_at_compile_time!()
# Unquote les fonctions générées à la compilation
```

### Phase 2.2: Validation automatique

Valider les paramètres selon les schémas OpenAPI avant l'appel API.

```elixir
validate_params(operation_id, params)
```

### Phase 2.3: Webhooks automatiques

Générer les handlers pour les webhooks Stancer à partir de la spec.

### Phase 2.4: Type checking avancé

Utiliser les schémas OpenAPI pour créer des types Elixir plus précis (ex: Union types pour les énums).

## Tests

Tous les tests sont dans `test/stancer_test.exs`:

```bash
mix test
```

Tests couverts:
- ✅ Export des fonctions manuelles
- ✅ Chargement de la spec OpenAPI
- ✅ Extraction des endpoints
- ✅ Appels dynamiques d'endpoints
- ✅ Gestion d'erreurs
- ✅ Documentation intégrée

## Notes de développement

### Dépendances

- `req` — HTTP client
- `jason` — JSON parsing

### Logs

Le module loggue les informations au niveau `info`:
```elixir
Logger.info("Loaded Stancer OpenAPI spec, generating 150+ endpoint functions")
```

### Limitations actuelles

1. Les fonctions avec paramètres de chemin (path parameters) ne sont pas encore générées
2. La validation des paramètres n'est pas encore automatique
3. Les schémas complexes ne sont pas encore typés

## Ressources

- **OpenAPI spec**: https://docs.stancer.com/api/openapi.json
- **Stancer API docs**: https://docs.stancer.com/
- **Elixir Quote/Unquote**: https://hexdocs.pm/elixir/Kernel.SpecialForms.html#quote/2
- **Elixir Macros**: https://hexdocs.pm/elixir/macros.html
