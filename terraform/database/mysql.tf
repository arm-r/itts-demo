resource "google_sql_database_instance" "mysql-itts" {
  name             = "mysql-itts-instance"
  database_version = "MYSQL_5_7"
  region           = "asia-southeast2"

  settings {
    tier = "db-f1-micro"
  }
}