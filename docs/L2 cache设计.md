## L2cache设计

组数：暂定两路，后期实验修正

替换策略：

写入策略：写回配合写分配

容量参数：参数化，后期实验修正

对于tag和data的访问写成串行







Q：

L1 L写直达	L2 写回

Inclusive	Exclusive？In：L2cache包含L1cache的所有数据

Inclusive：浪费空间，简化一致性检测	推荐用

是否需要victim cache、filter cache、write buffer?	暂无

是否阻塞？	不知道（不过好像和设计无关）

​	

![image-20230516165745675](C:\Users\lenovo\AppData\Roaming\Typora\typora-user-images\image-20230516165745675.png)





完成AXI总线的同时设计一个cpu直接访问的控制器，无cache，用于检测其余部分的正确性。

状态机

![QQ截图20230516164949](C:\Users\lenovo\Desktop\QQ截图20230516164949.png)

L1cache写入同时写入L2cache，可以保证Inclusive

L2使用dirty标志，采用写回

写分配：从主存调回cache改，主存暂时不改

中断、例外、异常在cache中的处理？

实现bit和半字的存储，需要一个type	？？需要吗





## AXI总线

ARESETn采用低电平复位。需要注意的是ARVALID，AWVALID，WVALID，RVALID，BVALID（这几个信号的含义会在后面说明）在复位时必须保证是处于低电平的。









## 小会

并行串行	若成为关键路径	优化一个多选器（data是合并的）

预取

一个line存在一个被频繁修改的值的优化

小dirty位

L1cache	简化	LRU

L2cache 复杂替换策略

