FROM nimlang/nim:2.0.4-ubuntu

WORKDIR /root
ADD entrypoint.sh .
RUN chmod u+x entrypoint.sh
ADD test_suite_1.nim .

RUN nimble install -y unittest2

ENTRYPOINT ["/root/entrypoint.sh"]
