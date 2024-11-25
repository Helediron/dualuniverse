echo "This will regenerate market orders in MyDU. Updating may take long time..."
if [ ! -f ./config/dual.yaml ]; then
    echo "You are in wrong directory. Move to MyDU folder."
    exit 1
fi

docker-compose run -v "$PWD:/input" --entrypoint "python3 /python/seed_markets.py --orders-folder /input/data/market_orders/ --dual-conf /input/config/dual.yaml --flush run" sandbox
echo "Orders updated."
