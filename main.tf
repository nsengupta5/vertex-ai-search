terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.0.0"
    }
  }
  required_version = ">= 0.13"
}

provider "google" {
  project               = var.project_id
  billing_project       = var.billing_project
  region                = var.region
  user_project_override = true
}

# Enable the Cloud Resource Manager API
resource "google_project_service" "cloud_resource_manager_api" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"

  disable_on_destroy = false
}

# Enable the Discovery Engine API 
resource "google_project_service" "discovery_engine_api" {
  project = var.project_id
  service = "discoveryengine.googleapis.com"

  disable_on_destroy = false
  depends_on         = [google_project_service.cloud_resource_manager_api]
}

# Enable the Vertex AI API
resource "google_project_service" "vertex_ai_api" {
  project = var.project_id
  service = "aiplatform.googleapis.com"

  disable_on_destroy = false
  depends_on         = [google_project_service.cloud_resource_manager_api]
}

# Create a Data Store
resource "google_discovery_engine_data_store" "basic" {
  location          = var.location
  data_store_id     = var.data_store_id
  display_name      = var.data_store_display_name
  industry_vertical = "GENERIC"
  solution_types    = ["SOLUTION_TYPE_SEARCH"]
  content_config    = "CONTENT_REQUIRED"
  depends_on        = [google_project_service.discovery_engine_api]
}

# Create a Search Engine
resource "google_discovery_engine_search_engine" "basic" {
  engine_id      = var.search_engine_id
  collection_id  = var.collection_id
  location       = google_discovery_engine_data_store.basic.location
  display_name   = var.search_engine_display_name
  data_store_ids = [google_discovery_engine_data_store.basic.data_store_id]
  search_engine_config {
    search_tier    = "SEARCH_TIER_ENTERPRISE"
    search_add_ons = ["SEARCH_ADD_ON_LLM"]
  }
}

# Create a GCS Data Source
resource "google_storage_bucket" "data_source" {
  name                        = var.bucket_name
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy               = true
}
