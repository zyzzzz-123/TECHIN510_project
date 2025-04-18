import streamlit as st

# 模拟目标数据
goals = [
    {"title": "📚 Academic Growth", "progress": 60},
    {"title": "💡 Personal Growth", "progress": 40},
    {"title": "🎨 Learn a New Skill", "progress": 20}
]

# 模拟今日任务
if "tasks" not in st.session_state:
    st.session_state.tasks = [
        {"text": "Finish 1 chapter of HCI textbook", "done": False},
        {"text": "Watch 30-min tutorial on Figma", "done": False}
    ]

st.title("🎯 My Goals")

# 展示每个目标
for goal in goals:
    st.subheader(goal["title"])
    st.progress(goal["progress"] / 100)

st.markdown("---")

st.header("🗓️ Today's Tasks")
for i, task in enumerate(st.session_state.tasks):
    col1, col2 = st.columns([0.8, 0.2])
    with col1:
        st.write("✅" if task["done"] else "🔘", task["text"])
    with col2:
        if st.button("Done", key=f"done-{i}"):
            st.session_state.tasks[i]["done"] = True

# 添加新任务
st.markdown("### ➕ Add New Task")
new_task = st.text_input("Task Description", key="new_task")
if st.button("Add Task"):
    if new_task:
        st.session_state.tasks.append({"text": new_task, "done": False})
        st.success("Task added!")
        st.experimental_rerun()
    else:
        st.warning("Please enter a task description.")