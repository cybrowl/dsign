#!/bin/bash

# Start tasks in background
npm run test-config &
npm run test-pc &
npm run test-pi &
npm run test-p &
npm run test-ps &

# Wait for all background tasks to finish
wait
