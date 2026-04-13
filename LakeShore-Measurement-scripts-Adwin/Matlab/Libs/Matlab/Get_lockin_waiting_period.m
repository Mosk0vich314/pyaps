function periods = Get_lockin_waiting_period(filter_order, accuracy_value)

accuracy = [63.2 90 99 99.9];
accuracy_idx = min(abs(accuracy-accuracy_value)) == abs(accuracy-accuracy_value);

table = [1	2.3	4.61	6.91;
    2.15	3.89	6.64	9.23;
    3.26	5.32	8.41	11.23;
    4.35	6.68	10.05	13.06;
    5.43	7.99	11.6	14.79;
    6.51	9.27	13.11	16.45;
    7.58	10.53	14.57	18.06;
    8.64	11.77	16	19.62;
    ];

periods = table(filter_order,accuracy_idx);

end