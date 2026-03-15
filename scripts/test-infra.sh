#!/bin/bash

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

if [ -z "$PROJECT_ROOT" ]; then
    echo "not in a git repository. run this from your microsocket folder"
    exit 1
fi

cd "$PROJECT_ROOT" || exit 1

echo "checking microsocket setup in $PROJECT_ROOT"
echo ""

echo "1. docker:"
if command -v docker &> /dev/null; then
    echo "  ✅ ok $(docker --version | head -n1)"
else
    echo "  ❌ missing docker"
fi
echo ""

echo "2. docker compose:"
if command -v docker-compose &> /dev/null; then
    echo "  ✅ ok $(docker-compose --version | head -n1)"
else
    echo "  ❌ missing compose"
fi
echo ""

echo "3. postgres:"
if docker ps | grep -q microsocket-postgres; then
    echo "  ✅ container up"
    if docker exec microsocket-postgres pg_isready -U postgres &> /dev/null; then
        echo "    ✅ can connect"
    else
        echo "    ❌ cant connect"
    fi
else
    echo "  ❌ postgres not running"
fi
echo ""

echo "4. redis:"
if docker ps | grep -q microsocket-redis; then
    echo "  ✅ container up"
    if docker exec microsocket-redis redis-cli ping | grep -q PONG; then
        echo "    ✅ pong"
    else
        echo "    ❌ no response"
    fi
else
    echo "  ❌ redis not running"
fi
echo ""

echo "5. rabbitmq:"
if docker ps | grep -q microsocket-rabbitmq; then
    echo "  ✅ container up"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:15672)
    if [ "$HTTP_CODE" == "200" ]; then
        echo "    ✅ ui works"
    else
        echo "    ❌ ui returned $HTTP_CODE"
    fi
else
    echo "  ❌ rabbitmq not running"
fi
echo ""

echo "6. running containers:"
RUNNING=$(docker-compose ps --services --filter "status=running" 2>/dev/null)
if [ -n "$RUNNING" ]; then
    echo "$RUNNING" | while read service; do
        echo "  ✅ $service"
    done
else
    echo "  none running"
fi
echo ""

echo "7. ports:"
if command -v ss &> /dev/null; then
    PORT_CHECK="ss -tln"
elif command -v netstat &> /dev/null; then
    PORT_CHECK="netstat -tln"
else
    PORT_CHECK=""
    echo "  cant check ports"
fi

if [ -n "$PORT_CHECK" ]; then
    $PORT_CHECK | grep -q :5432 && echo "  ✅ 5432 postgres" || echo "  ❌ 5432 missing"
    $PORT_CHECK | grep -q :6379 && echo "  ✅ 6379 redis" || echo "  ❌ 6379 missing"
    $PORT_CHECK | grep -q :5672 && echo "  ✅ 5672 rabbitmq" || echo "  ❌ 5672 missing"
    $PORT_CHECK | grep -q :15672 && echo "  ✅ 15672 rabbitmq ui" || echo "  ❌ 15672 missing"
fi
echo ""

if [ -f "docker-compose.yml" ]; then
    RUNNING_COUNT=$(docker-compose ps --services --filter "status=running" 2>/dev/null | wc -l)
    TOTAL_COUNT=$(docker-compose ps --services 2>/dev/null | wc -l)

    if [ "$RUNNING_COUNT" -eq "$TOTAL_COUNT" ] && [ "$TOTAL_COUNT" -gt 0 ]; then
        echo "✅ all containers running"
    elif [ "$RUNNING_COUNT" -gt 0 ]; then
        echo "⚠️  $RUNNING_COUNT/$TOTAL_COUNT running"
        echo "run: docker-compose up -d"
    else
        echo "❌ no containers running"
        echo "run: make setup"
    fi
else
    echo "❌ no docker-compose.yml found in $PROJECT_ROOT"
fi

echo ""
echo "rabbitmq ui: http://localhost:15672 (guest/guest)"
