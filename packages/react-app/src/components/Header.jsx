import { PageHeader } from "antd";
import React from "react";

// displays a page header

export default function Header() {
  return (
    <a href="https://nftschool.dev" target="_blank" rel="noopener noreferrer">
      <PageHeader
        title="🐝 Fancy bee"
        subTitle="Forked code at nftschool.dev"
        style={{ cursor: "pointer" }}
      />
    </a>
  );
}
