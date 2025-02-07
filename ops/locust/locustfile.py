from locust import HttpUser, task, between

class LoadTestUser(HttpUser):
    wait_time = between(1, 2)  # Wait time between requests (in seconds)

    @task
    def get_products(self):
        self.client.get("/api/products")
