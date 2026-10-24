import { render, screen } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import { ProfileCard } from "./ProfileCard";

describe("ProfileCard", () => {
  it("shows the display name", () => {
    render(<ProfileCard user={{ displayName: "Asha", bioHtml: "Hello" }} />);
    expect(screen.getByRole("heading", { name: "Asha" })).toBeTruthy();
  });
});
