失败的任务是: local171 , 分析这些任务为啥失败, 我们可能在执行过程中发现很多执行错误的sql, 我们需要把他们规范划具体的错误类型:
# 如何找到具体的任务:
SELECT t.*
FROM ai_task_info t
WHERE taskInfo like '%localxxxx%'
ORDER BY created_at DESC
LIMIT 1
然后可以从ai_task_ui_message_item找到所有的执行明细
SELECT t.*
FROM ai_task_ui_message_item t
LIMIT 501

工具方向的错误:
1. The tool execution failed with the following error: 是工具错误的前缀, 你需要分析工具错误的具体原因, 你需要告诉我是什么原因,
结果方向的错误:
我们所有的标准结果都在/Users/zhaown/workspace/ai_project/ai_project/Spider2/spider2-lite/evaluation_suite/gold/exec_result, 然后我们的解法是在/Users/zhaown/workspace/ai_project/ai_project/Spider2/spider2-lite/evaluation_suite/example_submission_folder_csv, 当然具体的流程表中也有ai_task_api_message_item, 你需要分析过程判断为什么出错了, 然后优化我们的skill: /Users/zhaown/workspace/ai_project/nest_admin_source/jayce2/infiniSynapse/skills/.system/infini-sql-analysis
什么情况可以被优化? 就是你发现这些错误是可以在skills中被提醒的,并且是可以通用警告的一个错误,如果回答的ai_task_api_message_item已经收到对应提示, 但是AI没有注意, 那我们就不管, 或者你觉得提示确实不够, 我们就优化下. 如果是我们没有提到,或者以前没注意过的注意点,我们就好优化skills, 让他变的更强