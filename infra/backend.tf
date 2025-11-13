terraform {
    backend "s3" {
        bucket = "cloudsec-ir-lab-tfstate-bc"
        key = "terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "cloudsec-ir-lab-locks"
        encrypt = true
    }
}