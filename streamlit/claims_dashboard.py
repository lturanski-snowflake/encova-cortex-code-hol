import streamlit as st
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="Encova Claims Dashboard", layout="wide")

session = get_active_session()

@st.cache_data(ttl=300)
def load_claims():
    return session.sql("SELECT * FROM GOLD.CLAIMS_GOLD").to_pandas()

df = load_claims()

st.title("Encova Claims Analytics Dashboard")

with st.sidebar:
    st.header("Filters")
    lobs = ["All"] + sorted(df["LINE_OF_BUSINESS"].dropna().unique().tolist())
    selected_lob = st.multiselect("Line of Business", options=lobs[1:], default=[])

    statuses = sorted(df["CLAIM_STATUS"].dropna().unique().tolist())
    selected_status = st.multiselect("Claim Status", options=statuses, default=[])

    severity_opts = ["All", "LOW", "MEDIUM", "HIGH"]
    selected_severity = st.selectbox("Severity", options=severity_opts)

filtered = df.copy()
if selected_lob:
    filtered = filtered[filtered["LINE_OF_BUSINESS"].isin(selected_lob)]
if selected_status:
    filtered = filtered[filtered["CLAIM_STATUS"].isin(selected_status)]
if selected_severity != "All":
    filtered = filtered[filtered["SEVERITY"] == selected_severity]

col1, col2, col3, col4 = st.columns(4)
col1.metric("Total Claims", f"{len(filtered):,}")
col2.metric("Total Incurred", f"${filtered['TOTAL_INCURRED'].sum():,.0f}")
col3.metric("Avg Claim", f"${filtered['ESTIMATED_AMOUNT'].mean():,.0f}")
col4.metric(
    "Open Claims",
    f"{(filtered['CLAIM_STATUS'] == 'OPEN').sum():,}",
)

tab1, tab2, tab3 = st.tabs(["Claims Overview", "AI Insights", "Risk & Fraud"])

with tab1:
    col_a, col_b = st.columns(2)
    with col_a:
        st.subheader("Claims by Line of Business")
        lob_counts = (
            filtered.groupby("LINE_OF_BUSINESS")
            .size()
            .reset_index(name="CLAIM_COUNT")
            .sort_values("CLAIM_COUNT", ascending=False)
        )
        st.bar_chart(lob_counts.set_index("LINE_OF_BUSINESS")["CLAIM_COUNT"])

    with col_b:
        st.subheader("Top 10 States by Total Incurred")
        state_inc = (
            filtered.groupby("LOSS_LOCATION_STATE")["TOTAL_INCURRED"]
            .sum()
            .reset_index()
            .sort_values("TOTAL_INCURRED", ascending=False)
            .head(10)
        )
        st.bar_chart(state_inc.set_index("LOSS_LOCATION_STATE")["TOTAL_INCURRED"])

with tab2:
    col_a, col_b = st.columns(2)
    with col_a:
        st.subheader("AI Complexity Class")
        complexity = (
            filtered.groupby("AI_COMPLEXITY_CLASS")
            .agg(CLAIM_COUNT=("CLAIM_ID", "count"), AVG_AMOUNT=("ESTIMATED_AMOUNT", "mean"))
            .reset_index()
            .sort_values("CLAIM_COUNT", ascending=False)
        )
        st.bar_chart(complexity.set_index("AI_COMPLEXITY_CLASS")["CLAIM_COUNT"])

    with col_b:
        st.subheader("Sentiment Distribution")
        sent = (
            filtered["DESCRIPTION_SENTIMENT"]
            .value_counts()
            .reset_index()
            .rename(columns={"index": "SENTIMENT", "DESCRIPTION_SENTIMENT": "COUNT"})
        )
        st.bar_chart(sent.set_index("DESCRIPTION_SENTIMENT"))

    st.subheader("Top 10 Damage Types (AI Extracted)")
    damage = (
        filtered["AI_EXTRACTED_DAMAGE_TYPE"]
        .dropna()
        .value_counts()
        .head(10)
        .reset_index()
        .rename(columns={"index": "DAMAGE_TYPE", "AI_EXTRACTED_DAMAGE_TYPE": "COUNT"})
    )
    st.bar_chart(damage.set_index("AI_EXTRACTED_DAMAGE_TYPE"))

with tab3:
    col_a, col_b, col_c = st.columns(3)
    fraud_count = (filtered["FRAUD_INDICATOR"] != "NONE").sum()
    lit_count = filtered["LITIGATION_FLAG"].sum()
    high_risk = (filtered["RISK_SCORE"] >= 70).sum()
    col_a.metric("Fraud Flagged", f"{fraud_count:,}")
    col_b.metric("In Litigation", f"{lit_count:,}")
    col_c.metric("High Risk (Score ≥ 70)", f"{high_risk:,}")

    st.subheader("Risk Score Distribution")
    bins = [0, 20, 40, 60, 80, 100]
    labels = ["0-20", "21-40", "41-60", "61-80", "81-100"]
    filtered = filtered.copy()
    filtered["RISK_BUCKET"] = (
        filtered["RISK_SCORE"]
        .pipe(lambda s: s.apply(
            lambda x: labels[min(int(x // 20), 4)] if x is not None else None
        ))
    )
    risk_dist = (
        filtered["RISK_BUCKET"]
        .value_counts()
        .reindex(labels, fill_value=0)
        .reset_index()
        .rename(columns={"index": "BUCKET", "RISK_BUCKET": "COUNT"})
    )
    st.bar_chart(risk_dist.set_index("RISK_BUCKET"))
