%ʵ��Ҫ��һ�������źű���ʵ��
clear all; clc; close all;

[xx,fs]=audioread('C7_4_y.wav');                     % ��ȡ�ļ�
xx=xx-mean(xx);                           % ȥ��ֱ������
x=xx/max(abs(xx));                        % ��һ��
N=length(x);                              % ���ݳ���
time=(0:N-1)/fs;                          % �źŵ�ʱ��̶�
wlen=240;                                 % ֡��
inc=80;                                   % ֡��
overlap=wlen-inc;                         % �ص�����
tempr1=(0:overlap-1)'/overlap;            % б���Ǵ�����w1
tempr2=(overlap-1:-1:0)'/overlap;         % б���Ǵ�����w2
n2=1:wlen/2+1;                            % ��Ƶ�ʵ��±�ֵ
X=enframe(x,wlen,inc)';                   % ��֡
fn=size(X,2);                             % ֡��
T1=0.1; r2=0.5;                           % �˵������
miniL=10;                                 % �л������֡��
mnlong=5;                                 % Ԫ���������֡��
ThrC=[10 15];                             % ��ֵ
p=12;                                     % LPC�״�
frameTime=FrameTimeC(fn,wlen,inc,fs);     % ����ÿ֡��ʱ��̶�
in=input('����������������ʱ�䳤����ԭ����ʱ�䳤�ȵı���:','s');%�����������ȱ���
rate=str2num(in);

for i=1 : fn                              % ��ȡÿ֡��Ԥ��ϵ��������
    u=X(:,i);
    [ar,g]=lpc(u,p);
    AR_coeff(:,i)=ar;
    Gain(i)=g;
end

% �������
[voiceseg,vosl,SF,Ef,period]=pitch_Ceps(x,wlen,inc,T1,fs); %���ڵ��׷��Ļ������ڼ��
Dpitch=pitfilterm1(period,voiceseg,vosl);       % ��T0����ƽ�����������������T0

tal=0;                                    % ��ʼ��
zint=zeros(p,1); 
%% LSP��������ȡ
for i=1 : fn
    a2=AR_coeff(:,i);                     % ȡ����֡��Ԥ��ϵ��
    lsf=lpctolsf(a2);                       % ����ar2lsf�������lsf
    Glsf(:,i)=lsf;                        % ��lsf�洢��Glsf������
end

% ͨ���ڲ����Ӧ�������̻��쳤
fn1=floor(rate*fn);                        % �����µ���֡��fn1
Glsfm=interp1((1:fn),Glsf',linspace(1,fn,fn1))';% ��LSFϵ���ڲ�
Dpitchm=interp1(1:fn,Dpitch,linspace(1,fn,fn1));% �ѻ��������ڲ�
Gm=interp1((1:fn),Gain,linspace(1,fn,fn1));%������ϵ���ڲ�
SFm=interp1((1:fn),SF,linspace(1,fn,fn1)); %��SFϵ���ڲ�

%% �����ϳ�
for i=1:fn1; 
    lsf=Glsfm(:,i);                       % ��ȡ��֡��lsf����
    ai=lsftolpc(lsf);                       % ����lsf2ar������lsfת����Ԥ��ϵ��ar 
    sigma=sqrt(Gm(i));

    if SFm(i)==0                          % �޻�֡
        excitation=randn(wlen,1);         % ����������
        [synt_frame,zint]=filter(sigma,ai,excitation,zint);
    else                                  % �л�֡
        PT=round(Dpitchm(i));             % ȡ����ֵ
        exc_syn1 =zeros(wlen+tal,1);      % ��ʼ�����巢����
        exc_syn1(mod(1:tal+wlen,PT)==0)=1;% �ڻ������ڵ�λ�ò������壬��ֵΪ1
        exc_syn2=exc_syn1(tal+1:tal+inc); % ����֡��inc�����ڵ��������
        index=find(exc_syn2==1);
        excitation=exc_syn1(tal+1:tal+wlen);% ��һ֡�ļ�������Դ
        
        if isempty(index)                 % ֡��inc������û������
            tal=tal+inc;                  % ������һ֡��ǰ�����
        else                              % ֡��inc������������
            eal=length(index);            % �����м�������
            tal=inc-index(eal);           % ������һ֡��ǰ�����
        end
        gain=sigma/sqrt(1/PT);            % ����
        [synt_frame,zint]=filter(gain,ai,excitation,zint);%�ü�������ϳ�����
    end
    
    if i==1                               % ��Ϊ��1֡
            output=synt_frame;            % ����Ҫ�ص����,�����ϳ�����
        else
            M=length(output);             % �ص����ֵĴ���
            output=[output(1:M-overlap); output(M-overlap+1:M).*tempr1+...
                synt_frame(1:overlap).*tempr2; synt_frame(overlap+1:wlen)];
        end
end
output(find(isnan(output)))=0;
bn=[0.964775   -3.858862   5.788174   -3.858862   0.964775]; % �˲���ϵ��
an=[1.000000   -3.928040   5.786934   -3.789685   0.930791];
output=filter(bn,an,output);             % ��ͨ�˲�
output=output/max(abs(output));          % ��ֵ��һ��

%% ��ͼ
% figure(1)
ol=length(output);                        % ������ݳ���
time1=(0:ol-1)/fs;                        % ���������е�ʱ������
sound(output)
subplot 211; plot(time,x,'k'); title('ԭʼ��������'); 
axis([0 max(time) -1 1]); xlabel('ʱ��/s'); ylabel('��ֵ')
subplot 212; plot(time1,output,'k');  title('�ϳ���������');
xlim([0 max(time1)]); xlabel('ʱ��/s'); ylabel('��ֵ')


