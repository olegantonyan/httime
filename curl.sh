#!/bin/sh

time curl -X GET 'http://localhost:3003/time?Moscow,Kaliningrad,New%20York,nonexistent,Vologda,Yerevan'
