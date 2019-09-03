Rails.configuration.stripe = if Rails.env.production?
  {
    publishable_key: Rails.application.credentials.dig(ENV['PRODUCTION_ENVIRONMENT'].to_sym, :stripe, :publishable_key),
    secret_key: Rails.application.credentials.dig(ENV['PRODUCTION_ENVIRONMENT'].to_sym, :stripe, :secret_key)
  }
else
  {
    publishable_key: "pk_test_OCBXc8VhHcjiMHHJV9KRy5fd",
    secret_key: "sk_test_j9dU0Xe5BoTgCexiNIj7jpxh"
  }
end

Stripe.api_key = Rails.configuration.stripe[:secret_key]
Stripe.api_version = "2019-05-16"
