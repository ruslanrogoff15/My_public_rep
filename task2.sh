#!/bin/bash

sum=0

echo "Вводите числа по одному (0 для завершения):"

while true; do
       read number
    
      if [ "$number" -eq 0 ]; then
           echo "Сумма: $sum"
        break
    fi
    
      sum=$((sum + number))
done
