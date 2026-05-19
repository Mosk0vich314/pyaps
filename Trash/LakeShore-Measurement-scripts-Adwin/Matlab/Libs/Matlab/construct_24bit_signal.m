function [Gate]  =  construct_24bit_signal(Settings, Gate)

voltagesD = linspace(Settings.output_min, Settings.output_max, 2^Settings.output_resolution);
idx = find(min(abs(Gate.Vout-voltagesD))==abs(Gate.Vout-voltagesD));
VoutD = idx(1);
VoutA = voltagesD(idx(1));

VoutDLower = find(voltagesD<Gate.Vout,1,'last');
VoutDHigher = VoutDLower + 1;
VoutALower = voltagesD(VoutDLower);
VoutAHigher = voltagesD(VoutDHigher);

Gate.ratioUpLow = (Gate.Vout-VoutALower)/(VoutAHigher-VoutALower);
Gate.signalAmountHigher = round(Gate.ratioUpLow*Gate.signalLength);
Gate.signalAmountLower = Gate.signalLength - Gate.signalAmountHigher;

VoutDLower = VoutDLower - 2;
VoutDHigher = VoutDHigher - 2;

Gate.signalSent = zeros(Gate.signalLength,1);
Gate.signalSent(1:Gate.signalAmountLower) = VoutDLower;
Gate.signalSent(Gate.signalAmountLower+1:Gate.signalLength) = VoutDHigher;
Gate.VoutNew = (Gate.signalAmountLower*VoutALower + Gate.signalAmountHigher*VoutAHigher)/Gate.signalLength;

VpairCount = floor(length(Gate.signalSent)/2);
randomIntegersSignalWidth = randi([-Gate.SignalWidth Gate.SignalWidth],1,VpairCount);

for i = 1:VpairCount
    Gate.signalSent((i-1)*2 + 1) = Gate.signalSent((i-1)*2 + 1) + randomIntegersSignalWidth(i);
    Gate.signalSent((i-1)*2 + 2) = Gate.signalSent((i-1)*2 + 2) - randomIntegersSignalWidth(i);
end

Gate.signalSent = Gate.signalSent(randperm(length(Gate.signalSent)));

voltagesOut = voltagesD(Gate.signalSent);
Gate.voltagesOutAv = mean(voltagesOut);
return