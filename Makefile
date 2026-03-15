.PHONY: setup start stop logs clean

setup:
	@echo "Creating .env file..."
	cp .env.example .env
	@echo "Starting infrastructure..."
	docker-compose up -d
	@echo "Done! Services running:"
	docker-compose ps

start:
	docker-compose up -d

stop:
	docker-compose down

logs:
	docker-compose logs -f

clean:
	docker-compose down -v
	rm -rf .env
