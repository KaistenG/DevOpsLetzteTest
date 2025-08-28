from locust import HttpUser, task, between

class FlaskUser(HttpUser):
    wait_time = between(1, 3)

    @task
    def index(self):
        self.client.get("/")