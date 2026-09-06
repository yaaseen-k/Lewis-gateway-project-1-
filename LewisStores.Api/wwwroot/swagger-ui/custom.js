window.addEventListener("load", () => {
  const topbarLink = document.querySelector(".swagger-ui .topbar-wrapper a");
  if (topbarLink) {
    topbarLink.setAttribute("target", "_self");
  }

  const infoSection = document.querySelector(".swagger-ui .info");
  if (!infoSection) {
    return;
  }

  const notice = document.createElement("div");
  notice.style.marginTop = "14px";
  notice.style.padding = "14px 16px";
  notice.style.border = "1px solid #c6dde2";
  notice.style.borderRadius = "10px";
  notice.style.background = "linear-gradient(135deg, #f4fbfb 0%, #eef8ff 100%)";
  notice.style.color = "#123f4b";
  notice.style.fontSize = "13px";
  notice.style.lineHeight = "1.55";
  notice.innerHTML = "<strong>Integration Quick Start</strong><br/>1) Authenticate using <em>POST /api/Auth/login</em>.<br/>2) Select <em>Authorize</em> and provide the JWT token value only.<br/>3) Validate role-based behaviors against commerce, returns, support, and QA scenario endpoints.";

  infoSection.appendChild(notice);
});
