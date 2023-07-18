# print("gh           <=0;");
# for i in range(16):
#     print("chkpt_q[4'd"+str(i)+"]<=0;");

for i in range(1,16):
    print("chkpt_q[4'd"+str(i)+"]<=chkpt_q[4'd"+str(i-1)+"];");