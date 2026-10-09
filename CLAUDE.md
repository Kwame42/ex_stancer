# CLAUDE.md — Stancer API Client Library

## Contexte

Librairie Elixir pour intégrer Stancer (payment processor français) dans les projets Phoenix.
C'est un client HTTP minimaliste utilisant **Req** pour les requêtes.

**Spec**: https://docs.stancer.com/api/openapi.json

---

## Architecture

### Module Principal : `Stancer`

- **Récupère la clé API** depuis la config Elixir (pas en dur)
- **Utilise Req** pour les requêtes HTTP
- **Gère les erreurs** et le logging
- **Interface simple** : fonction par endpoint

### Configuration

```elixir
# config/config.exs
config :stancer,
  api_key: System.get_env("STANCER_API_KEY"),
  api_url: "https://api.stancer.com",
  api_version: "v1"
```

---

## API Disponible

### Tokenisation de carte
```elixir
Stancer.tokenize_card(%{
  "card" => %{
    "number" => "4111111111111111",
    "exp_month" => 12,
    "exp_year" => 2026,
    "cvc" => "123"
  }
})
# => {:ok, %{"id" => "card_...", ...}}
```

### Créer un paiement (autorisation sans capture)
```elixir
Stancer.create_payment(%{
  "amount" => 5000,  # en centimes (50€)
  "currency" => "EUR",
  "card" => card_token,  # token retourné par tokenize_card
  "capture" => false  # important : sans capture
})
# => {:ok, %{"id" => "paym_...", "status" => "authorized"}}
```

### Capturer un paiement
```elixir
Stancer.capture_payment(payment_id, 5000)
# => {:ok, %{"status" => "captured"}}
```

### Rembourser un paiement
```elixir
Stancer.refund_payment(payment_id)
# => {:ok, %{"status" => "refunded"}}
```

### Récupérer une carte
```elixir
Stancer.get_card(card_token)
# => {:ok, %{"id" => "card_...", ...}}
```

### Supprimer une carte
```elixir
Stancer.delete_card(card_token)
# => {:ok, ...}
```

---

## Roadmap (Métaprogrammation & API Design)

### Phase 1 ✅
- ✅ Client Stancer basique avec endpoints clés
- ✅ Configuration via config Elixir

### Phase 2 ✅ (Refactored)
- ✅ Clean, hierarchical API structure (`Stancer.API.ResourceName`)
- ✅ Standard CRUD functions per resource (list, create, get, update, delete)
- ✅ Full documentation with examples
- ✅ Type-safe @spec declarations
- ✅ Consistent error handling
- ✅ OpenAPI loader and generator modules (foundation for future generation)
- ✅ Full test coverage

**Structure:**
```
Stancer.API.Customers.list()       # GET /customers
Stancer.API.Customers.create(data) # POST /customers
Stancer.API.Customers.get(id)      # GET /customers/{id}
Stancer.API.Customers.update(id, data) # PUT /customers/{id}
Stancer.API.Customers.delete(id)   # DELETE /customers/{id}

Stancer.API.Payments.* (same pattern)
Stancer.API.Cards.* (same pattern)
```

### Phase 3 (TODO)
- Auto-generate remaining resource modules from OpenAPI spec
- Support for additional resource types (Mandates, Subscriptions, Disputes, Webhooks, etc.)
- Validation layer based on OpenAPI schemas
- Specialized functions for complex operations (capture, refund, etc.)
- Webhook handler generation

---

## Endpoints HTTP (à partir d'OpenAPI)

- `POST /tokens` → `Stancer.tokenize_card/1`
- `POST /payments` → `Stancer.create_payment/1`
- `GET /payments/{id}` → `Stancer.get_payment/1`
- `POST /payments/{id}/capture` → `Stancer.capture_payment/2`
- `POST /payments/{id}/refund` → `Stancer.refund_payment/2`
- `GET /cards/{id}` → `Stancer.get_card/1`
- `DELETE /cards/{id}` → `Stancer.delete_card/1`

---

## Erreurs courantes

| Erreur | Cause | Solution |
|--------|-------|----------|
| `"Access Denied"` | Clé API manquante/invalide | Vérifier `STANCER_API_KEY` |
| `"Invalid card"` | Données carte incomplètes | Vérifier tous les champs requis |
| `"Amount too low"` | Montant < 50 centimes | Augmenter le montant |
| `"Currency not supported"` | Devise non supportée | Utiliser EUR, USD, GBP, etc. |

---

## Tests

```bash
cd /Users/kwame/rosepourpre/stancer
mix test
```

---

## Dépendances

- `:req` — HTTP client (recommandé par Elixir)
- `:jason` — JSON parsing

---

## Notes de sécurité

⚠️ **IMPORTANT** :
- Ne **JAMAIS** logger la clé API complète
- **TOKENISER** la carte côté client quand possible (mais ok aussi côté serveur)
- Les données de carte ne restent **JAMAIS** en base — seulement le token
- Utiliser **HTTPS** uniquement (enforced par Stancer)
- **Ne pas capturer** automatiquement, laisser admin confirmer


